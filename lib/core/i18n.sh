#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core - Motor de Internacionalización (i18n)
# ==============================================================================

init_i18n() {
    local default_lang="en"
    local selected_lang="${default_lang}"
    
    # 1. Detectar el idioma nativo del host a través del entorno
    if [[ -n "${LANG:-}" ]]; then
        # Extrae los dos primeros caracteres (ej: "es" de "es_ES.UTF-8")
        local sys_lang="${LANG%%_*}"
        
        if [[ -f "${BASE_DIR}/lang/${sys_lang}.sh" ]]; then
            selected_lang="${sys_lang}"
        fi
    fi
    
    # 2. Carga segura del diccionario de traducción correspondiente
    # shellcheck source=/dev/null
    source "${BASE_DIR}/lang/${selected_lang}.sh"
}