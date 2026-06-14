#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior - Orquestador Principal de Infraestructura (v1.0-RC1)
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
source "${BASE_DIR}/lib/ui/menu.sh"
source "${BASE_DIR}/lib/ui/dialogs.sh"

main() {
    # 1. Validaciones de entorno en el Host (Fases 1-3)
    check_root
    validate_interactive_terminal
    validate_os
    validate_architecture
    
    # 2. Preparación de dependencias del sistema operativo
    validate_required_packages
    install_docker_engine
    
    # Commit 2: Gestión idempotente y segura de la red global (Control de errores real)
    log_info "Configurando infraestructura global compartida..."
    if docker network inspect dw_proxy_network &>/dev/null; then
        log_info "La red global 'dw_proxy_network' ya existe. Reutilizando infraestructura."
    else
        log_info "Creando red global compartida 'dw_proxy_network'..."
        if docker network create dw_proxy_network >/dev/null; then
            log_success "Red global 'dw_proxy_network' creada con éxito."
        else
            log_error "Fallo crítico al crear la red 'dw_proxy_network'."
            log_error "Verifique que el daemon de Docker esté activo y respondiendo."
            exit 1
        fi
    fi
    
    # Commit 1: Carga pura de módulos core (Sin efectos secundarios automáticos)
    if [[ -f "${BASE_DIR}/apps/core/dockge.sh" ]]; then
        source "${BASE_DIR}/apps/core/dockge.sh"
    fi
    if [[ -f "${BASE_DIR}/apps/core/portainer.sh" ]]; then
        source "${BASE_DIR}/apps/core/portainer.sh"
    fi
    
    # Invocación explícita y secuencial bajo nomenclatura unificada
    log_info "Instalando componentes de infraestructura base..."
    install_dockge
    install_portainer
    
    # 3. Captura del catálogo dinámico (Interfaz Whiptail)
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
    
    # 4. Bucle de despliegue declarativo con Política Fail-Fast Estricta
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
    
    # 5. Resumen de Salida y Cierre de Operaciones
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