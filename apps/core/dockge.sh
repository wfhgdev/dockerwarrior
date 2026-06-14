#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core App - Dockge Management Suite (Idempotent Lifecycle)
# ==============================================================================

install_dockge() {
    log_info "Iniciando instalación del orquestador visual Dockge..."
    
    local dockge_dir="/opt/dockge"
    local stacks_dir="/opt/stacks"
    local compose_file="${dockge_dir}/compose.yaml"
    
    # Verificar si la infraestructura declarativa de Dockge ya fue creada en el host
    if [[ -f "${compose_file}" ]]; then
        
        # Caso 1: El stack de Compose ya existe y está activo/saludable
        if [[ "$(docker compose -f "${compose_file}" ps --filter "status=running" -q)" ]]; then
            log_info "Dockge ya está desplegado y funcionando. Reutilizando instalación existente."
            return 0
        fi
        
        # Caso 2: El archivo compose existe pero los servicios están caídos o pausados
        log_info "Dockge está configurado en el host pero el stack está detenido. Levantando entorno..."
        if docker compose -f "${compose_file}" up -d &>/dev/null; then
            log_success "Dockge se ha reactivado correctamente en el puerto 5001."
            return 0
        else
            log_error "Fallo crítico al intentar levantar el stack existente de Dockge."
            return 1
        fi
    fi
    
    # Caso 3: Instalación limpia desde cero
    log_info "No se detectó configuración previa de Dockge. Inicializando directorios..."
    mkdir -p "${dockge_dir}" "${stacks_dir}"
    
    # Escribir la definición del compose de infraestructura de forma estática
    cat << 'EOF' > "${compose_file}"
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

    # Lanzamiento del orquestador inicial
    if docker compose -f "${compose_file}" up -d &>/dev/null; then
        log_success "Dockge se ha desplegado correctamente en el puerto 5001."
    else
        log_error "Fallo al inicializar el contenedor de Dockge desde origen."
        return 1
    fi
    
    return 0
}