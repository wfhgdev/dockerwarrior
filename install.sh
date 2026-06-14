#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior - Orquestador Principal de Infraestructura
# ==============================================================================
set -Eeuo pipefail

# Definición e importación de la ruta base del proyecto
export BASE_DIR
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carga de subsistemas y librerías Core
source "${BASE_DIR}/lib/core/logger.sh"
source "${BASE_DIR}/lib/core/utils.sh"
source "${BASE_DIR}/lib/core/system.sh"
source "${BASE_DIR}/lib/core/engine.sh"
source "${BASE_DIR}/lib/ui/menus.sh"

main() {
    # 1. Validaciones de entorno en el Host (Fases 1-3)
    check_root
    validate_interactive_terminal
    validate_os
    validate_architecture
    
    # 2. Preparación de dependencias del sistema operativo
    validate_required_packages
    install_docker_engine
    
    # 3. Inicialización de Infraestructura Común Global
    log_info "Configurando infraestructura global compartida..."
    docker network create dw_proxy_network 2>/dev/null || true
    
    # 4. Despliegue de herramientas base de gestión (Core Apps)
    # Estos scripts se invocan desde apps/core/ de forma nativa
    if [[ -f "${BASE_DIR}/apps/core/dockge.sh" ]]; then
        source "${BASE_DIR}/apps/core/dockge.sh"
    fi
    if [[ -f "${BASE_DIR}/apps/core/portainer.sh" ]]; then
        source "${BASE_DIR}/apps/core/portainer.sh"
    fi
    
    # 5. Captura del catálogo dinámico (Interfaz Whiptail)
    local selected_apps_str
    selected_apps_str=$(ui_select_apps)
    
    # Convertir la salida de la interfaz en una lista iterable de Bash
    read -r -a app_array <<< "${selected_apps_str}"
    
    if [[ ${#app_array[@]} -eq 0 ]]; then
        log_warn "Instalación finalizada. No se seleccionaron stacks adicionales."
        exit 0
    fi
    
    log_info "Procesando el despliegue de ${#app_array[@]} stack(s)..."
    echo ""
    
    # 6. Bucle de despliegue declarativo con Política Fail-Fast Estricta
    for app_id in "${app_array[@]}"; do
        if ! core_deploy_app "${app_id}"; then
            echo ""
            log_error "======================================================================"
            log_error "Fallo crítico en la preparación del servicio: ${app_id}"
            log_error "Instalación abortada de inmediato para proteger la consistencia."
            log_error "======================================================================"
            exit 1
        fi
        echo "" 
    done
    
    # 7. Resumen de Salida y Cierre de Operaciones
    echo "======================================================================"
    log_success "DockerWarrior ha finalizado correctamente."
    echo ""
    echo "Stacks preparados:"
    for app_id in "${app_array[@]}"; do
        echo -e " \e[32m✓\e[0m ${app_id}"
    done
    echo ""
    echo "Ubicación de los Stacks:"
    echo " /opt/stacks/"
    echo ""
    echo "Siguiente paso obligatorio:"
    echo " Acceda al panel web de Dockge para levantar los entornos preparados."
    echo "======================================================================"
}

main "$@"