#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior UI - Abstracciones de Cuadros de Diálogo (Whiptail Wrapper)
# ==============================================================================

ui_checklist() {
    local title="${1}"
    local subtitle="${2}"
    shift 2
    local options=("$@")
    
    # Dimensionamiento adaptativo base para la interfaz de consola
    local height=20
    local width=72
    local list_height=10
    
    # Ejecución controlada redirigiendo canales de salida de datos estándar
    whiptail --title "${title}" \
             --checklist "${subtitle}" \
             "${height}" "${width}" "${list_height}" \
             "${options[@]}" \
             3>&1 1>&2 2>&3
}