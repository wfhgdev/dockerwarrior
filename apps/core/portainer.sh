#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core App - Portainer Community Edition
# ==============================================================================

install_portainer() {
    log_info "Iniciando instalación del administrador avanzado Portainer CE..."
    
    local portainer_volume="portainer_data"
    
    # Crear volumen persistente si no existe
    if ! docker volume inspect "${portainer_volume}" &>/dev/null; then
        docker volume create "${portainer_volume}" >/dev/null
    fi
    
    # Lanzar el contenedor de Portainer de infraestructura
    if docker run -d \
        -p 9443:9443 \
        --name portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "${portainer_volume}":/data \
        portainer/portainer-ce:latest &>/dev/null; then
        log_success "Portainer CE se ha desplegado correctamente en el puerto https 9443."
    else
        log_error "Fallo al inicializar el contenedor de Portainer."
        return 1
    fi
    
    return 0
}