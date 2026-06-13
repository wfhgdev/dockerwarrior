#!/usr/bin/env bash

validate_os() { 
    log_info "Validando Sistema Operativo..."
    # Lógica base para asegurar que es Debian/Ubuntu
}

validate_architecture() { 
    log_info "Validando Arquitectura..."
}

validate_hardware() { 
    log_info "Validando Recursos de Hardware..."
}

validate_required_packages() {
    log_info "Instalando dependencias críticas (whiptail, curl)..."
    apt-get update -qq
    apt-get install -y whiptail curl ca-certificates > /dev/null
}

validate_interactive_terminal() {
    log_info "Verificando disponibilidad de terminal interactivo..."
    
    if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
        log_error "Entorno no interactivo detectado (Falta TTY)."
        exit 1
    fi

    if [[ -z "${TERM:-}" || "${TERM}" == "dumb" ]]; then
        log_error "La variable de entorno \$TERM no está definida o es incompatible."
        exit 1
    fi
    
    log_success "Terminal interactivo (TTY) confirmado."
}
