#!/usr/bin/env bash

load_language() {
    local lang_code="${1:-}"
    
    if [[ -z "${lang_code}" ]]; then
        lang_code=$(echo "${LANG:-en}" | cut -c 1-2)
    fi

    local lang_file="${BASE_DIR}/lang/${lang_code}.sh"
    
    if [[ ! -f "${lang_file}" ]]; then
        log_warn "Idioma '${lang_code}' no encontrado. Aplicando inglés por defecto."
        lang_file="${BASE_DIR}/lang/en.sh"
    fi
    
    # shellcheck source=/dev/null
    source "${lang_file}"
}

ui_main_menu() {
    if ! ui_confirm "${MSG_WELCOME_TITLE}" "${MSG_WELCOME_TEXT}"; then
        log_info "Instalación cancelada por el usuario en la pantalla de bienvenida."
        exit 0
    fi
}

ui_select_apps() {
    local apps_file="${BASE_DIR}/config/apps.conf"
    local checklist_args=()
    
    while IFS='|' read -r app_id app_name category || [[ -n "${app_id}" ]]; do
        [[ -z "${app_id}" || "${app_id}" =~ ^# ]] && continue
        
        local desc_var="APP_${app_id^^}_DESC"
        local app_desc="${!desc_var:-$app_name}"
        
        checklist_args+=("${app_id}" "${app_name} - ${app_desc}" "OFF")
    done < "${apps_file}"

    local selections
    selections=$(ui_checklist "${MSG_MENU_TITLE}" "${MSG_MENU_TEXT}" "${checklist_args[@]}")
    
    echo "${selections}" | tr -d '"'
}
