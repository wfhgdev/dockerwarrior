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
    
    local selected_apps_str
    selected_apps_str=$(ui_select_apps)
    
    # Convertir la salida de whiptail (espacios) en un array
    read -r -a app_array <<< "${selected_apps_str}"
    
    if [[ ${#app_array[@]} -eq 0 ]]; then
        log_warn "No se seleccionó ninguna aplicación para desplegar."
    else
        log_info "Iniciando despliegue de ${#app_array[@]} stack(s)..."
        
        # Bucle de despliegue (Fase 6)
        for app_id in "${app_array[@]}"; do
            if ! core_deploy_app "${app_id}"; then
                log_error "Falló el despliegue de ${app_id}."
                log_error "Abortando instalación por política fail-fast."
                exit 1
            fi
            echo "" # Espaciado estético para la consola
        done
        
        # Resumen Final (Pre-Fase 7)
        echo "======================================================================"
        log_success "DockerWarrior ha finalizado correctamente."
        echo ""
        echo "Stacks preparados:"
        for app_id in "${app_array[@]}"; do
            echo -e " \e[32m✓\e[0m ${app_id}"
        done
        echo ""
        echo "Ubicación:"
        echo " /opt/stacks/"
        echo ""
        echo "Siguiente paso:"
        echo " Acceda a Dockge y despliegue los stacks preparados."
        echo "======================================================================"
    fi

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
