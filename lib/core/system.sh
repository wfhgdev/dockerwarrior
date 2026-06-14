#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core - Validaciones de Sistema y Aprovisionamiento Base
# ==============================================================================

check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        log_error "Este script debe ejecutarse con privilegios de root (sudo)."
        exit 1
    fi
}

validate_interactive_terminal() {
    log_info "Verificando disponibilidad de terminal interactivo..."
    if [[ ! -t 0 ]]; then
        log_error "DockerWarrior requiere un terminal interactivo (TTY)."
        exit 1
    fi
    log_success "Terminal interactivo (TTY) confirmado."
}

validate_os() {
    log_info "Validando Sistema Operativo..."
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "${ID}" != "ubuntu" && "${ID}" != "debian" ]]; then
            log_error "Sistema Operativo no soportado (${NAME}). Requiere Ubuntu o Debian."
            exit 1
        fi
    else
        log_error "No se pudo determinar el Sistema Operativo del Host."
        exit 1
    fi
}

validate_architecture() {
    log_info "Validando Arquitectura..."
    local arch
    arch=$(uname -m)
    if [[ "${arch}" != "x86_64" && "${arch}" != "aarch64" ]]; then
        log_error "Arquitectura de CPU no soportada (${arch}). Requiere x86_64 o arm64."
        exit 1
    fi
}

validate_required_packages() {
    log_info "Instalando dependencias críticas (whiptail, curl)..."
    local deps=(whiptail curl openssl gnupg ca-certificates)
    local missing_deps=()

    for pkg in "${deps[@]}"; do
        if ! command -v "${pkg}" &>/dev/null; then
            missing_deps+=("${pkg}")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        apt-get update &>/dev/null
        apt-get install -y "${missing_deps[@]}" &>/dev/null
    fi
}

install_docker_engine() {
    if command -v docker &>/dev/null; then
        log_info "Docker Engine ya se encuentra instalado en el sistema."
        return 0
    fi

    log_info "Instalando Docker Engine oficial desde los repositorios..."
    
    # Preparar el directorio de llaveros del sistema de paquetes
    mkdir -p /etc/apt/keyrings
    chmod 0755 /etc/apt/keyrings
    
    # Importar clave GPG oficial del proyecto Docker de forma segura
    source /etc/os-release
    curl -fsSL "https://download.docker.com/linux/${ID}/gpg" | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg &>/dev/null
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Registrar el repositorio apt oficial correspondiente a la distribución
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} \
      $(lsb_release -cs 2>/dev/null || echo "${VERSION_CODENAME}") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Sincronizar e instalar la suite de contenedores nativa
    apt-get update &>/dev/null
    if apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>/dev/null; then
        log_success "Docker Engine y complementos de orquestación configurados correctamente."
    else
        log_error "Fallo crítico al aprovisionar Docker Engine a través de apt."
        return 1
    fi

    return 0
}