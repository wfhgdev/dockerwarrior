#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core - Motor de Plantillas y Despliegue Dinámico (v1.0)
# ==============================================================================

# Enrutador de placeholders: Evalúa y retorna el valor de cada token detectado
resolve_placeholder() {
    local token="${1}"
    local type="${token%%:*}"
    local arg="${token#*:}"
    
    if [[ "${type}" == "${arg}" ]]; then
        arg=""
    fi

    case "${type}" in
        SECRET)
            local length="${arg:-32}"
            openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | head -c "${length}"
            ;;
        SYSTEM_TZ)
            cat /etc/timezone 2>/dev/null || echo "UTC"
            ;;
        BASE_DOMAIN)
            echo "${GLOBAL_BASE_DOMAIN:-${BASE_DOMAIN:-micasa.duckdns.org}}"
            ;;
        GLOBAL)
            local var_name="GLOBAL_${arg}"
            echo "${!var_name:-}"
            ;;
        *)
            echo "UNRESOLVED_${token}"
            ;;
    esac
}

# Analizador léxico: Procesa las plantillas línea a línea de forma segura
process_template() {
    local template_file="${1}"
    local output_file="${2}"

    # Crear el archivo de destino vacío con permisos 600 estrictos desde el primer instante
    touch "${output_file}"
    chmod 600 "${output_file}"
    > "${output_file}"

    while IFS= read -r line || [[ -n "${line}" ]]; do
        while [[ "${line}" =~ (.*)\{\{([^}]+)\}\}(.*) ]]; do
            local prefix="${BASH_REMATCH[1]}"
            local token="${BASH_REMATCH[2]}"
            local suffix="${BASH_REMATCH[3]}"

            local resolved_value
            resolved_value=$(resolve_placeholder "${token}")
            line="${prefix}${resolved_value}${suffix}"
        done
        echo "${line}" >> "${output_file}"
    done < "${template_file}"
}

# Pipeline principal de aprovisionamiento
core_deploy_app() {
    local app_id="${1}"
    local template_dir="${BASE_DIR:-.}/templates/${app_id}"
    local target_dir="/opt/stacks/${app_id}"
    
    echo -e "\e[34m[INFO]\e[0m Iniciando despliegue de infraestructura: ${app_id}"

    if [[ ! -d "${template_dir}" ]]; then
        echo -e "\e[31m[ERROR]\e[0m Directorio de plantillas no encontrado: ${template_dir}" >&2
        return 1
    fi

    # Cargar metadatos extensibles de la aplicación
    local meta_file="${template_dir}/metadata.conf"
    if [[ -f "${meta_file}" ]]; then
        # shellcheck source=/dev/null
        source "${meta_file}"
    else
        echo -e "\e[33m[WARN]\e[0m metadata.conf no encontrado para: ${app_id}" >&2
    fi

    # Verificar si la aplicación requiere validaciones de red previas (Soporte Array DW-AppSpec v1.0)
    if declare -p REQUIRED_NETWORKS &>/dev/null; then
        for net in "${REQUIRED_NETWORKS[@]}"; do
            if ! docker network inspect "${net}" >/dev/null 2>&1; then
                echo -e "\e[31m[ERROR]\e[0m Red global requerida no encontrada: ${net}" >&2
                return 1
            fi
        done
    fi

    # Hook Pre-Instalación ejecutado de forma aislada (Proceso Hijo)
    if [[ -f "${template_dir}/pre_install.sh" ]]; then
        if ! bash "${template_dir}/pre_install.sh" "${app_id}"; then
            echo -e "\e[31m[ERROR]\e[0m El hook pre_install de ${app_id} falló." >&2
            return 1
        fi
    fi

    # Crear estructura destino en producción
    mkdir -p "${target_dir}"
    chmod 750 "${target_dir}"

    # Copiar archivos base de orquestación estática
    if [[ -f "${template_dir}/compose.yaml" ]]; then
        cp "${template_dir}/compose.yaml" "${target_dir}/compose.yaml"
    else
        echo -e "\e[31m[ERROR]\e[0m compose.yaml ausente en ${template_dir}" >&2
        return 1
    fi

    # Procesar mapa de variables de entorno
    if [[ -f "${template_dir}/env.template" ]]; then
        if ! process_template "${template_dir}/env.template" "${target_dir}/.env"; then
            echo -e "\e[31m[ERROR]\e[0m Error procesando el archivo env.template" >&2
            return 1
        fi
    fi

    # Hook Post-Instalación ejecutado de forma aislada (Proceso Hijo)
    if [[ -f "${template_dir}/post_install.sh" ]]; then
        if ! bash "${template_dir}/post_install.sh" "${app_id}" "${target_dir}"; then
            echo -e "\e[31m[ERROR]\e[0m El hook post_install de ${app_id} falló." >&2
            return 1
        fi
    fi

    echo -e "\e[32m[OK]\e[0m ${APP_NAME:-$app_id} preparado correctamente en ${target_dir}"
    return 0
}