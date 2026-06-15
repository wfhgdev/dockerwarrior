#!/usr/bin/env bash
# =============================================================================
# DockerWarrior Core - Motor de Plantillas y Despliegue Dinámico (v1.3.1-RC1)
# Branch: feature/engine-v1.3-hardening
# =============================================================================

# --- LOGGERS PORTABLES DE EMERGENCIA (POSIX Compliant) ---
# Se ejecutan de manera integrada si el subsistema logger.sh no se ha cargado.
_engine_log_info() {
    if command -v log_info &>/dev/null; then
        log_info "$1"
    else
        printf "\033[34m[INFO]\033[0m %s\n" "$1" >&2
    fi
}

_engine_log_success() {
    if command -v log_success &>/dev/null; then
        log_success "$1"
    else
        printf "\033[32m[OK]\033[0m %s\n" "$1" >&2
    fi
}

_engine_log_error() {
    if command -v log_error &>/dev/null; then
        log_error "$1"
    else
        printf "\033[31m[ERROR]\033[0m %s\n" "$1" >&2
    fi
}

# --- ENRUTADOR SEGURO DE PLACEHOLDERS ---
# Evalúa y retorna el valor correspondiente a cada token detectado.
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
            
            # BLINDAJE C-1: Comprobar disponibilidad de dependencias binarias
            if ! command -v openssl &>/dev/null; then
                _engine_log_error "${LOG_ENGINE_ERR_OPENSSL_MISSING}"
                return 1
            fi

            # BLINDAJE C-2: Generación aislada en subshell sin fugas de tubería
            local secret
            secret=$(openssl rand -base64 128 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c "${length}")

            # BLINDAJE C-3: Validación explícita de nulidad y longitud exacta
            if [[ -z "${secret}" || ${#secret} -ne ${length} ]]; then
                _engine_log_error "${LOG_ENGINE_ERR_SECRET}"
                return 1
            fi

            printf "%s" "${secret}"
            ;;
        SYSTEM_TZ)
            cat /etc/timezone 2>/dev/null || printf "UTC"
            ;;
        BASE_DOMAIN)
            printf "%s" "${GLOBAL_BASE_DOMAIN:-${BASE_DOMAIN:-micasa.duckdns.org}}"
            ;;
        GLOBAL)
            local var_name="GLOBAL_${arg}"
            printf "%s" "${!var_name:-}"
            ;;
        *)
            printf "%s" "UNRESOLVED_${token}"
            ;;
    esac
    return 0
}

# --- ANALIZADOR LÉXICO SEGURO DE PLANTILLAS ---
# Procesa archivos .template línea a línea mitigando estados intermedios sucios.
process_template() {
    local template_file="${1}"
    local output_file="${2}"
    local tmp_output="${output_file}.tmp"

    # BLOQUE B-1: Inicialización atómica mediante truncado directo limpia la basura previa
    if ! : > "${tmp_output}"; then
        _engine_log_error "${LOG_ENGINE_ERR_TMP_INIT}"
        return 1
    fi

    # BLOQUE B-2: Concesión inmediata de permisos 600 al archivo temporal
    if ! chmod 600 "${tmp_output}" 2>/dev/null; then
        rm -f "${tmp_output}"
        _engine_log_error "${LOG_ENGINE_ERR_TMP_PERMISSION}"
        return 1
    fi

    # BLOQUE B-3: Parseo seguro libre de efectos secundarios y control de errores en pipelines
    while IFS= read -r line || [[ -n "${line}" ]]; do
        local processed_line=""
        local remaining="${line}"

        while [[ "${remaining}" =~ \{\{([^}]+)\}\} ]]; do
            local match="${BASH_REMATCH[0]}"
            local token="${BASH_REMATCH[1]}"
            
            # Aislar el segmento estático izquierdo anterior al token
            processed_line="${processed_line}${remaining%%\{\{*}}"
            
            # Resolver token evaluando burbujeo de excepciones aguas abajo
            local resolved_value=""
            if ! resolved_value=$(resolve_placeholder "${token}"); then
                rm -f "${tmp_output}"
                return 1
            fi
            processed_line="${processed_line}${resolved_value}"
            
            # Truncar la porción procesada de la línea actual
            remaining="${remaining#*\}\}}"
        done
        processed_line="${processed_line}${remaining}"

        if ! printf "%s\n" "${processed_line}" >> "${tmp_output}"; then
            rm -f "${tmp_output}"
            _engine_log_error "${LOG_ENGINE_ERR_ENV_WRITE}"
            return 1
        fi
    done < "${template_file}"

    # BLOQUE B-4: Mutación transaccional en caliente (Atomic move) hacia producción
    if ! mv "${tmp_output}" "${output_file}"; then
        rm -f "${tmp_output}"
        _engine_log_error "${LOG_ENGINE_ERR_ENV_MOVE}"
        return 1
    fi

    # BLOQUE B-5: Verificación estricta de permisos persistentes en destino
    if ! chmod 600 "${output_file}" 2>/dev/null; then
        _engine_log_error "${LOG_ENGINE_ERR_ENV_PERMISSION}"
        return 1
    fi

    return 0
}

# --- MOTOR DE DESPLIEGUE ATÓMICO (TRANSACCIONAL) ---
deploy_app() {
    local app_id="${1}"
    local template_dir="${BASE_DIR}/templates/${app_id}"
    local target_dir="${DW_STACKS_DIR}/${app_id}"

    _engine_log_info "$(printf "${LOG_ENGINE_START}" "${app_id}")"

    # 1. Validar sintaxis y seguridad léxica del app_id
    if [[ ! "${app_id}" =~ ^[a-z0-9_-]+$ ]]; then
        _engine_log_error "$(printf "${LOG_ENGINE_ERR_INVALID_ID}" "${app_id}")"
        return 1
    fi

    # 2. Validar existencia del módulo empaquetado en el catálogo
    if [[ ! -d "${template_dir}" ]]; then
        _engine_log_error "$(printf "${LOG_ENGINE_ERR_TEMPLATE_MISSING}" "${app_id}")"
        return 1
    fi

    # 3. Fail-Fast: Validar que el directorio destino no se encuentre bloqueado por un archivo regular
    if [[ -f "${target_dir}" ]]; then
        _engine_log_error "$(printf "${LOG_ENGINE_ERR_TARGET_IS_FILE}" "${target_dir}")"
        return 1
    fi

    # 4. Crear de forma limpia el directorio destino (G-4: Preservar permisos si ya existía)
    if [[ ! -d "${target_dir}" ]]; then
        if ! mkdir -p "${target_dir}"; then
            _engine_log_error "$(printf "${LOG_ENGINE_ERR_MKDIR_FAIL}" "${target_dir}")"
            return 1
        fi
        chmod 750 "${target_dir}" 2>/dev/null
    fi

    # 5. Validar privilegios reales de escritura sobre el espacio del stack
    if [[ ! -w "${target_dir}" ]]; then
        _engine_log_error "$(printf "${LOG_ENGINE_ERR_WRITE_DENIED}" "${target_dir}")"
        return 1
    fi

    # 6. Copiar de forma segura el manifiesto compose.yaml
    local src_compose="${template_dir}/compose.yaml"
    local dst_compose="${target_dir}/compose.yaml"
    if [[ -f "${src_compose}" ]]; then
        if ! cp "${src_compose}" "${dst_compose}"; then
            _engine_log_error "${LOG_ENGINE_ERR_COMPOSE_COPY}"
            return 1
        fi
    else
        _engine_log_error "${LOG_ENGINE_ERR_COMPOSE_MISSING}"
        return 1
    fi

    # 7. Bloque D: Aplicar permisos controlados y uniformes al compose.yaml
    if ! chmod 640 "${dst_compose}" 2>/dev/null; then
        _engine_log_error "${LOG_ENGINE_ERR_COMPOSE_PERMISSION}"
        return 1
    fi

    # 8. Procesar y blindar atómicamente la inyección de variables (.env)
    local src_env_template="${template_dir}/env.template"
    local dst_env="${target_dir}/.env"
    if [[ -f "${src_env_template}" ]]; then
        if ! process_template "${src_env_template}" "${dst_env}"; then
            _engine_log_error "${LOG_ENGINE_ERR_ENV_FAILED}"
            return 1
        fi
    fi

    # 9. Ejecutar pre_install.sh solo tras garantizar el éxito absoluto del entorno base del stack
    local pre_script="${template_dir}/pre_install.sh"
    if [[ -f "${pre_script}" ]]; then
        _engine_log_info "$(printf "${LOG_ENGINE_HOOK_PRE_START}" "${app_id}")"
        if ! bash "${pre_script}" "${app_id}"; then
            _engine_log_error "$(printf "${LOG_ENGINE_HOOK_PRE_FAIL}" "${app_id}")"
            return 1
        fi
    fi

    # 10. Ejecutar post_install.sh en aislamiento secuencial
    local post_script="${template_dir}/post_install.sh"
    if [[ -f "${post_script}" ]]; then
        _engine_log_info "$(printf "${LOG_ENGINE_HOOK_POST_START}" "${app_id}")"
        if ! bash "${post_script}" "${app_id}"; then
            _engine_log_error "$(printf "${LOG_ENGINE_HOOK_POST_FAIL}" "${app_id}")"
            return 1
        fi
    fi

    # 11. Consolidación de éxito
    _engine_log_success "$(printf "${LOG_ENGINE_SUCCESS}" "${app_id}")"
    return 0
}