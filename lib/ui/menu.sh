#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior UI - Menú de Selección de Aplicaciones Dinámicas
# ==============================================================================

# PRUEBA SOLICITADA POR IA###########
#log_info "DEBUG: Entrando en ui_select_apps()"
# FIN PRUEBA SOLICITADA POR IA#############

ui_select_apps() {
    local apps_file="${BASE_DIR}/config/apps.conf"
    # PRUEBA SOLICITADA POR IA###########
    #log_info "DEBUG: Leyendo catálogo ${apps_file}"
    # FIN PRUEBA SOLICITADA POR IA#############
    if [[ ! -f "${apps_file}" ]]; then
        # PRUEBA SOLICITADA POR IA###########
        #log_info "DEBUG: Aplicaciones encontradas: ${#options[@]}"
        # FIN PRUEBA SOLICITADA POR IA#############
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
    local menu_title="${MSG_MENU_TITLE:-DockerWarrior - Selección de Aplicaciones}"
    local menu_subtitle="${MSG_MENU_SUBTITLE:-Seleccione las aplicaciones adicionales que desea preparar:}"

    # PRUEBA SOLICITADA POR IA###########
    #log_info "DEBUG: Lanzando interfaz Whiptail..."
    # FIN PRUEBA SOLICITADA POR IA#############

    choices=$(ui_checklist "${menu_title}" "${menu_subtitle}" "${options[@]}") || whiptail_status=$?
    
    # Clasificación estricta de salida del proceso interactivo
    if [[ "${whiptail_status}" -eq 0 ]]; then
        
        # feat(ui): Validación defensiva de IDs para blindar la frontera con el Core
        local check_array
        read -r -a check_array <<< "${choices}"
        
        for app_id in "${check_array[@]}"; do
            if [[ ! "${app_id}" =~ ^[a-z0-9_-]+$ ]]; then
                log_error "Identificador malicioso o inválido detectado en la capa UI: [${app_id}]" >&2
                return 4 # Código de error por fallo de seguridad / sanitización
            fi
        done
        
        echo "${choices}"
        return 0
    elif [[ "${whiptail_status}" -eq 1 || "${whiptail_status}" -eq 255 ]]; then
        # Código 3 asignado para cancelaciones explícitas del usuario
        return 3
    else
        # Código de error interno del componente de interfaz de usuario
        return 2
    fi
}