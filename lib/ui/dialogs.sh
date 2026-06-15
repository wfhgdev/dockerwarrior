#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior UI - Abstracciones de Cuadros de Diálogo (Whiptail Wrapper)
# ==============================================================================

ui_checklist() {
    if ! command -v whiptail >/dev/null 2>&1; then
        log_error "Whiptail no está instalado o no se encuentra disponible."
        return 2
    fi
    local title="${1}"
    local subtitle="${2}"
    shift 2
    local options=("$@")
    
    # Dimensionamiento adaptativo base para la interfaz de consola
    local height=20
    local width=72
    local list_height=10
    
    local choices
    local exit_status=0
    
    # Capturar de forma segura la salida redirigiendo descriptores de archivo
    choices=$(whiptail --title "${title}" \
             --checklist "${subtitle}" \
             "${height}" "${width}" "${list_height}" \
             "${options[@]}" \
             3>&1 1>&2 2>&3) || exit_status=$?
             
    # Si el usuario canceló o hubo error en el widget, propagar el código de salida inmediato
    if [[ "${exit_status}" -ne 0 ]]; then
        return "${exit_status}"
    fi
    
    # fix(ui): Sanitizar la salida eliminando comillas dobles generadas por Whiptail
    choices="${choices//\"/}"
    
    # Retornar la cadena normalizada limpia (ej: "app1 app2 app3")
    echo "${choices}"
    return 0
}