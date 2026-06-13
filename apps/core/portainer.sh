#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior - Despliegue de Portainer Community Edition
# ==============================================================================

deploy_portainer() {
    local portainer_dir="${STACKS_ROOT}/portainer"
    
    log_info "Configurando el Stack de Portainer en la ruta de Dockge..."
    mkdir -p "${portainer_dir}"

    log_info "Generando manifiesto Compose para Portainer CE (Versión ${VERSION_PORTAINER})..."
    
    cat <<EOF > "${portainer_dir}/compose.yaml"
services:
  portainer:
    image: portainer/portainer-ce:${VERSION_PORTAINER}
    container_name: dw-portainer
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    ports:
      - "${PORTAINER_PORT}:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/data
networks:
  default:
    name: ${DW_NETWORK}
    external: true
EOF

    log_info "Lanzando el Stack de Portainer..."
    cd "${portainer_dir}"
    docker compose up -d > /dev/null

    log_success "Portainer CE desplegado correctamente (HTTPS) en el puerto ${PORTAINER_PORT}."
}