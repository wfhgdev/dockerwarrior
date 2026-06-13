validate_interactive_terminal() {
    log_info "Verificando disponibilidad de terminal interactivo..."
    
    # 1. Comprobación primaria: File Descriptors (TTY)
    # -t 0 verifica entrada estándar (stdin)
    # -t 1 verifica salida estándar (stdout)
    if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
        log_error "Entorno no interactivo detectado (Falta TTY)."
        log_error "DockerWarrior requiere un terminal para la Fase 5. Para automatización, utilice el modo desatendido (Ej: --unattended) [Característica en desarrollo]."
        exit 1
    fi

    # 2. Comprobación secundaria: Variable de entorno TERM
    # Evita fallos críticos en Whiptail si se ejecuta a través de SSH rudimentarios o cron jobs
    if [[ -z "${TERM:-}" || "${TERM}" == "dumb" ]]; then
        log_error "La variable de entorno \$TERM no está definida o es incompatible ('${TERM:-vacía}')."
        log_error "Whiptail requiere un emulador de terminal válido (ej. xterm-256color)."
        exit 1
    fi
    
    log_success "Terminal interactivo (TTY) confirmado. Interfaz gráfica soportada."
}