#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior - Despliegue de Dockge (Administrador de Stacks)
# ==============================================================================

deploy_dockge() {
    log_info "Preparando el entorno de directorios para Dockge..."
    
    # Crear los directorios base definidos en defaults.conf
    mkdir -p "${STACKS_ROOT}" "${DOCKGE_ROOT}"

    log_info "Generando manifiesto Compose para Dockge (Versión ${VERSION_DOCKGE})..."
    
    cat <<EOF > "${DOCKGE_ROOT}/compose.yaml"
services:
  dockge:
    image: louislam/dockge:${VERSION_DOCKGE}
    container_name: dw-dockge
    restart: unless-stopped
    ports:
      - "${DOCKGE_PORT}:5001"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/app/data
      - ${STACKS_ROOT}:${STACKS_ROOT}
    environment:
      - DOCKGE_STACKS_DIR=${STACKS_ROOT}
networks:
  default:
    name: ${DW_NETWORK}
    external: true
EOF

    log_info "Lanzando el contenedor de Dockge..."
    cd "${DOCKGE_ROOT}"
    docker compose up -d > /dev/null
    
    log_success "Dockge desplegado correctamente en el puerto ${DOCKGE_PORT}."
}