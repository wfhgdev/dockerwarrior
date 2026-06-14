#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core App - Portainer Community Edition (Idempotent Lifecycle)
# ==============================================================================

install_portainer() {
    log_info "Iniciando instalación del administrador avanzado Portainer CE..."
    
    local container_name="portainer"
    local portainer_volume="portainer_data"

    # 1. Caso 1: El contenedor ya existe y está en ejecución
    if [[ "$(docker ps -q -f name=^/${container_name}$)" ]]; then
        log_info "Portainer ya está en ejecución. Reutilizando instalación existente."
        return 0
    fi

    # 2. Caso 2: El contenedor existe pero se encuentra detenido
    if [[ "$(docker ps -a -q -f name=^/${container_name}$)" ]]; then
        log_info "Portainer existe en el sistema pero está detenido. Iniciando contenedor..."
        if docker start "${container_name}" &>/dev/null; then
            log_success "Portainer se ha iniciado correctamente."
            return 0
        else
            log_error "Fallo crítico al intentar arrancar el contenedor existente de Portainer."
            return 1
        fi
    fi

    # 3. Caso 3: Portainer no existe (Instalación limpia)
    log_info "No se detectó ninguna instancia previa. Procediendo con el despliegue inicial..."
    
    # Crear volumen persistente de forma idempotente
    if ! docker volume inspect "${portainer_volume}" &>/dev/null; then
        docker volume create "${portainer_volume}" >/dev/null
    fi
    
    # Lanzar contenedor inicial sin colisiones
    if docker run -d \
        -p 9443:9443 \
        --name "${container_name}" \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "${portainer_volume}":/data \
        portainer/portainer-ce:latest &>/dev/null; then
        log_success "Portainer CE se ha desplegado correctamente en el puerto https 9443."
    else
        log_error "Fallo al inicializar el contenedor de Portainer desde cero."
        return 1
    fi
    
    return 0
}