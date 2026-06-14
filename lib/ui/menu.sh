#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior UI - Menú de Selección de Aplicaciones Dinámicas
# ==============================================================================

ui_select_apps() {
    local apps_file="${BASE_DIR}/config/apps.conf"
    
    if [[ ! -f "${apps_file}" ]]; then
        log_error "Archivo de configuración no encontrado: ${apps_file}" >&2
        return 2
    fi

    # Mapeo dinámico de opciones leyendo la especificación del catálogo
    local options=()
    while IFS='|' read -r app_id app_name category || [[ -n "${app_id}" ]]; do
        # Omitir líneas en blanco o comentarios documentales
        [[ -z "${app_id}" || "${app_id}" =~ ^# ]] && continue
        
        # Inyectar estructura de argumentos requerida por whiptail
        options+=("${app_id}" "${app_name} [${category}]" "OFF")
    done < "${apps_file}"

    if [[ ${#options[@]} -eq 0 ]]; then
        log_error "El catálogo de aplicaciones en config/apps.conf se encuentra vacío." >&2
        return 2
    fi

    local choices
    local whiptail_status=0
    
    # Invocación pasando variables de idioma protegidas contra diccionarios incompletos
    local menu_title="${MSG_MENU_TITLE}"
    local menu_subtitle="${MSG_MENU_SUBTITLE:-Seleccione las aplicaciones adicionales que desea preparar:}"
    
    choices=$(ui_checklist "${menu_title}" "${menu_subtitle}" "${options[@]}") || whiptail_status=$?
    
    # Clasificación estricta de salida del proceso interactivo
    if [[ "${whiptail_status}" -eq 0 ]]; then
        echo "${choices}"
        return 0
    elif [[ "${whiptail_status}" -eq 1 || "${whiptail_status}" -eq 255 ]]; then
        # Código 3 asignado para cancelaciones explícitas del usuario (Esc / Botón Cancelar)
        return 3
    else
        # Código de error interno del componente de interfaz de usuario
        return 2
    fi
}