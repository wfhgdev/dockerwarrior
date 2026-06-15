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
    local line_number=0

    while IFS='|' read -r app_id app_name category extra || [[ -n "${app_id}" ]]; do

        ((line_number++))

        # Ignorar comentarios y líneas vacías
        [[ -z "${app_id}" || "${app_id}" =~ ^# ]] && continue

        # Validar estructura exacta: id|nombre|categoria
        if [[ -n "${extra}" || -z "${app_name}" || -z "${category}" ]]; then
            log_warn "Entrada de catálogo mal formada descartada en línea ${line_number}"
            continue
        fi

        # Validar ID de aplicación
        if [[ ! "${app_id}" =~ ^[a-z0-9_-]+$ ]]; then
            log_warn "Entrada inválida descartada del catálogo: ${app_id}"
            continue
        fi

        # Crear opción segura para Whiptail
        options+=("${app_id}" "${app_name} [${category}]" "OFF")

    done < "${apps_file}"

    if [[ ${#options[@]} -eq 0 ]]; then
        log_error "El catálogo de aplicaciones en config/apps.conf se encuentra vacío." >&2
        return 2
    fi

    local choices
    local whiptail_status=0

    # Textos internacionalizados con fallback seguro
    local menu_title="${MSG_MENU_TITLE:-DockerWarrior - Selección de Aplicaciones}"
    local menu_subtitle="${MSG_MENU_SUBTITLE:-Seleccione las aplicaciones adicionales que desea preparar:}"

    choices=$(ui_checklist "${menu_title}" "${menu_subtitle}" "${options[@]}") || whiptail_status=$?

    # Validación de salida de Whiptail
    if [[ "${whiptail_status}" -eq 0 ]]; then

        local check_array
        read -r -a check_array <<< "${choices}"

        for app_id in "${check_array[@]}"; do
            if [[ ! "${app_id}" =~ ^[a-z0-9_-]+$ ]]; then
                log_error "Identificador malicioso o inválido detectado en la capa UI: [${app_id}]" >&2
                return 4
            fi
        done

        echo "${choices}"
        return 0

    elif [[ "${whiptail_status}" -eq 1 || "${whiptail_status}" -eq 255 ]]; then

        # Cancelación voluntaria del usuario
        return 3

    else

        # Error interno del componente de UI
        return 2

    fi
}