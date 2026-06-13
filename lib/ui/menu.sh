#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior - Lógica de Menús y Traducciones
# ==============================================================================

load_language() {
    local lang_code="${1:-}"
    
    # Detectar idioma del sistema operativo si no se forzó uno
    if [[ -z "${lang_code}" ]]; then
        lang_code=$(echo "${LANG:-en}" | cut -c 1-2)
    fi

    local lang_file="${BASE_DIR}/lang/${lang_code}.sh"
    
    # Fallback inquebrantable al inglés si el archivo de idioma no existe
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
    
    # Leer el archivo de metadatos de las aplicaciones
    while IFS='|' read -r app_id app_name category || [[ -n "${app_id}" ]]; do
        # Ignorar líneas vacías o comentarios
        [[ -z "${app_id}" || "${app_id}" =~ ^# ]] && continue
        
        # Construir la variable dinámica (ej. APP_NEXTCLOUD_DESC)
        local desc_var="APP_${app_id^^}_DESC"
        
        # Expansión indirecta: Toma el valor traducido o usa el nombre como fallback
        local app_desc="${!desc_var:-$app_name}"
        
        # Formato de Whiptail: ID, Texto a mostrar, Estado (ON/OFF)
        checklist_args+=("${app_id}" "${app_name} - ${app_desc}" "OFF")
    done < "${apps_file}"

    # Lanzar la interfaz gráfica encapsulada
    local selections
    selections=$(ui_checklist "${MSG_MENU_TITLE}" "${MSG_MENU_TEXT}" "${checklist_args[@]}")
    
    # Limpiar las comillas dobles que devuelve Whiptail ("app1" "app2" -> app1 app2)
    echo "${selections}" | tr -d '"'
}