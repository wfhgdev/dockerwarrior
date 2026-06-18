#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core - Motor de Internacionalización (i18n)
# ==============================================================================

init_i18n() {
    local base_path="${1:-.}"

    # 1. Validar si la variable externa ya fue provista de forma explícita y válida
    if [[ -n "${LANG_SELECTED:-}" ]]; then
        if [[ "${LANG_SELECTED}" != "es" && "${LANG_SELECTED}" != "en" ]]; then
            echo "[WARN] LANG_SELECTED '${LANG_SELECTED}' no es válida. Reestableciendo..." >&2
            LANG_SELECTED=""
        fi
    fi

    # 2. Si no está definida, comprobar interactividad para lanzar Whiptail
    if [[ -z "${LANG_SELECTED:-}" ]]; then
        if [[ -t 0 && -t 1 ]]; then
            local choice
            choice=$(whiptail --title "DockerWarrior Core Engine" \
                             --menu "Seleccione su idioma / Select your language:" 11 55 2 \
                             "1" "Español (es)" \
                             "2" "English (en)" \
                             3>&1 1>&2 2>&3)
            local exit_status=$?

            # Problema 3 Mitigado: Cancelar o cerrar con ESC aborta limpiamente la instalación
            if [[ ${exit_status} -ne 0 ]]; then
                echo "Instalación cancelada por el usuario / Installation cancelled by user." >&2
                exit 0
            fi

            if [[ "${choice}" == "1" ]]; then
                LANG_SELECTED="es"
            elif [[ "${choice}" == "2" ]]; then
                LANG_SELECTED="en"
            fi
        else
            # Fallback silencioso en entornos puramente headless o automatizados (CI/CD)
            LANG_SELECTED="en"
        fi
    fi

    export LANG_SELECTED

    # 3. Carga del archivo de diccionario correspondiente usando el path inyectado
    local lang_file="${base_path}/lang/${LANG_SELECTED}.sh"
    if [[ -f "${lang_file}" ]]; then
        # shellcheck source=/dev/null
        source "${lang_file}"
    else
        echo "[ERR] Archivo de idioma ausente o no accesible: ${lang_file}" >&2
        exit 1
    fi
}