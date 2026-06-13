# ... Código anterior de install.sh (Añadir debajo de las variables previas)

# Importar configuraciones globales obligatoriamente
# shellcheck source=config/defaults.conf
source "${BASE_DIR}/config/defaults.conf"
# shellcheck source=config/versions.conf
source "${BASE_DIR}/config/versions.conf"

# Importar librerías de infraestructura Docker
# shellcheck source=lib/docker/install.sh
source "${BASE_DIR}/lib/docker/install.sh"
# shellcheck source=lib/docker/network.sh
source "${BASE_DIR}/lib/docker/network.sh"

# Importar instaladores de aplicaciones Core
# shellcheck source=apps/core/dockge.sh
source "${BASE_DIR}/apps/core/dockge.sh"
# shellcheck source=apps/core/portainer.sh
source "${BASE_DIR}/apps/core/portainer.sh"

# ... (Manejador de errores trap se mantiene igual)

main() {
    clear
    echo "======================================================================"
    echo "                 🛡️  BIENVENIDO A DOCKERWARRIOR 🛡️"
    echo "======================================================================"
    echo ""
    
    check_root
    init_log_file
    
    # Suite de auditoría (Fase 3)
    validate_os
    validate_architecture
    validate_hardware
    validate_required_packages
    
    log_success "El entorno base cumple con todos los requisitos."
    echo ""

    # Ejecución de la infraestructura (Fase 4)
    log_info "Iniciando despliegue de la infraestructura de contenedores..."
    install_docker_engine
    configure_dw_network
    
    log_info "Instalando interfaces de administración web..."
    deploy_dockge
    deploy_portainer

    echo ""
    log_success "======================================================================"
    log_success " 🎉 ¡ENTORNO CORE DESPLEGADO CON ÉXITO! 🎉"
    log_success "======================================================================"
    log_success "  ➜ Dockge (HTTP):  http://IP-DE-TU-SERVIDOR:${DOCKGE_PORT}"
    log_success "  ➜ Portainer (HTTPS): https://IP-DE-TU-SERVIDOR:${PORTAINER_PORT}"
    log_success "======================================================================"
    echo ""
    log_info "Preparado para proceder a la Fase 5 (Menús interactivos e internacionalización)..."
}

main "$@"