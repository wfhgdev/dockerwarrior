#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core - Sistema Centralizado de Logging
# ==============================================================================

LOG_FILE="/var/log/dockerwarrior.log"


init_log_file() {
    touch "${LOG_FILE}"
    chmod 600 "${LOG_FILE}"
}


# ------------------------------------------------------------------------------
# Función interna de escritura de logs
#
# Diseño:
# - Consola humana  -> STDERR
# - Archivo de log  -> /var/log/dockerwarrior.log
# - STDOUT queda reservado para intercambio de datos entre funciones
# ------------------------------------------------------------------------------
_log_write() {
    local level="$1"
    local color="$2"
    local message="$3"

    local formatted_message="\e[${color}m[${level}]\e[0m ${message}"

    # Mostrar en consola sin contaminar STDOUT
    echo -e "${formatted_message}" >&2

    # Guardar versión sin colores en el log persistente
    echo "[${level}] ${message}" >> "${LOG_FILE}"
}


log_info() {
    _log_write "INFO" "34" "$1"
}


log_success() {
    _log_write "OK" "32" "$1"
}


log_warn() {
    _log_write "WARN" "33" "$1"
}


log_error() {
    _log_write "ERROR" "31" "$1"
}