#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior - Instalador de Docker Engine & Plugins
# ==============================================================================

install_docker_engine() {
    if command -v docker &> /dev/null; then
        log_success "Docker ya está instalado en el sistema: $(docker --version)"
        return 0
    fi

    log_info "Instalando dependencias previas de Docker..."
    apt-get update -qq
    apt-get install -y ca-certificates curl gnupg > /dev/null

    log_info "Configurando el llavero GPG oficial de Docker..."
    install -m 0755 -d /etc/apt/keyrings
    
    # Obtener el ID del sistema operativo dinámicamente (ubuntu o debian)
    local os_id
    os_id=$(. /etc/os-release && echo "$ID")

    curl -fsSL "https://download.docker.com/linux/${os_id}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    chmod a+r /etc/apt/keyrings/docker.gpg

    log_info "Añadiendo el repositorio oficial a las fuentes de APT..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${os_id} \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    log_info "Instalando Docker Engine y Docker Compose Plugin..."
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null

    # Habilitar e iniciar el demonio de Docker
    systemctl enable --now docker > /dev/null
    
    log_success "Docker Engine y Docker Compose instalados de forma segura."
}