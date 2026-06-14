#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core App - Dockge Management Suite
# ==============================================================================

install_dockge() {
    log_info "Iniciando instalación del orquestador visual Dockge..."
    
    local dockge_dir="/opt/dockge"
    local stacks_dir="/opt/stacks"
    
    # Garantizar directorios operativos del sistema
    mkdir -p "${dockge_dir}" "${stacks_dir}"
    
    # Descargar o escribir compose.yaml local para Dockge de forma estática
    cat << 'EOF' > "${dockge_dir}/compose.yaml"
services:
  dockge:
    image: 'louislam/dockge:1'
    restart: unless-stopped
    ports:
      - '5001:5001'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/app/data
      - /opt/stacks:/opt/stacks
    environment:
      - DOCKGE_STACKS_DIR=/opt/stacks
EOF

    # Levantar la instancia Core de administración de forma nativa
    if docker compose -f "${dockge_dir}/compose.yaml" up -d &>/dev/null; then
        log_success "Dockge se ha desplegado correctamente en el puerto 5001."
    else
        log_error "Fallo al inicializar el contenedor de Dockge."
        return 1
    fi
    
    return 0
}