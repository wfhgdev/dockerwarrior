#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Librerías Core
source "${BASE_DIR}/lib/core/logger.sh"
source "${BASE_DIR}/lib/core/utils.sh"
source "${BASE_DIR}/lib/core/system.sh"

# Configuraciones
source "${BASE_DIR}/config/defaults.conf"
source "${BASE_DIR}/config/versions.conf"

# Interfaz e i18n (NUEVO)
source "${BASE_DIR}/lib/ui/dialogs.sh"
source "${BASE_DIR}/lib/ui/menu.sh"

# Módulos de Docker
source "${BASE_DIR}/lib/docker/install.sh"
source "${BASE_DIR}/lib/docker/network.sh"
source "${BASE_DIR}/apps/core/dockge.sh"
source "${BASE_DIR}/apps/core/portainer.sh"

error_handler() {
    local exit_code="${1}"
    local line_number="${2}"
    log_error "Fallo inesperado en la línea ${line_number} (Código: ${exit_code})."
    log_error "Registro completo en: ${LOG_FILE}"
    exit "${exit_code}"
}

trap 'error_handler $? $LINENO' ERR

main() {
    clear
    check_root
    init_log_file
    
    log_info "1. Secuencia de auditoría del entorno..."
    validate_interactive_terminal
    validate_os
    validate_architecture
    validate_hardware
    validate_required_packages
    
    # Cargar idioma basado en el sistema
    load_language ""
    
    # Mostrar menús antes de instalar nada
    ui_main_menu
    
    local selected_apps
    selected_apps=$(ui_select_apps)
    
    clear
    log_info "Iniciando despliegue de la infraestructura..."
    
    install_docker_engine
    configure_dw_network
    deploy_dockge
    deploy_portainer

    echo ""
    log_success "======================================================================"
    log_success " 🎉 ENTORNO CORE DESPLEGADO CON ÉXITO "
    log_success "======================================================================"
    
    if [[ -z "${selected_apps}" ]]; then
        log_warn "No seleccionaste ninguna aplicación adicional."
    else
        log_info "Preparado para instalar: ${selected_apps}"
        log_info "(La lógica de instalación individual se implementará en la Fase 6)"
    fi
    echo "======================================================================"
}

main "$@"
