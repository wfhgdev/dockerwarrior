cat << 'EOF' > implement_engine.sh
#!/usr/bin/env bash
set -Eeuo pipefail

echo "⚙️ Construyendo el Motor Genérico de Despliegue..."

# 1. Crear el archivo del motor
cat << 'INNER' > lib/core/engine.sh
#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior - Motor Genérico de Plantillas y Despliegue
# ==============================================================================

# Enrutador de Tokens: Recibe el contenido de {{...}} y devuelve el valor real
resolve_placeholder() {
    local token="${1}"
    
    # Separar el TIPO del ARGUMENTO (ej: SECRET:32 -> type=SECRET, arg=32)
    local type="${token%%:*}"
    local arg="${token#*:}"
    
    # Si no hay dos puntos, arg será igual a type. Lo limpiamos.
    if [[ "${type}" == "${arg}" ]]; then
        arg=""
    fi

    case "${type}" in
        SECRET)
            local length="${arg:-32}"
            # Utilizamos openssl y tr (nativos en Ubuntu/Debian) para generar secretos seguros
            openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | head -c "${length}"
            ;;
        SYSTEM_TZ)
            cat /etc/timezone 2>/dev/null || echo "UTC"
            ;;
        GLOBAL)
            # Para variables como {{GLOBAL:DOMAIN}}. 
            # Requiere que exista una variable de entorno llamada GLOBAL_DOMAIN
            local var_name="GLOBAL_${arg}"
            echo "${!var_name:-}"
            ;;
        *)
            log_warn "Token no reconocido en plantilla: {{${token}}}" >&2
            echo "UNRESOLVED_${token}"
            ;;
    esac
}

# Analizador Léxico: Procesa el archivo env.template línea por línea
process_template() {
    local template_file="${1}"
    local output_file="${2}"

    # Vaciar o crear el archivo de salida con permisos restrictivos
    > "${output_file}"
    chmod 600 "${output_file}"

    # Leer línea a línea, preservando espacios en blanco (IFS=)
    while IFS= read -r line || [[ -n "${line}" ]]; do
        
        # Bucle para procesar múltiples placeholders en una sola línea
        while [[ "${line}" =~ (.*)\{\{([^}]+)\}\}(.*) ]]; do
            local prefix="${BASH_REMATCH[1]}"
            local token="${BASH_REMATCH[2]}"
            local suffix="${BASH_REMATCH[3]}"

            local resolved_value
            resolved_value=$(resolve_placeholder "${token}")

            # Reconstruir la línea con el valor inyectado
            line="${prefix}${resolved_value}${suffix}"
        done
        
        echo "${line}" >> "${output_file}"
    done < "${template_file}"
}

# Flujo Principal de Despliegue de Aplicación
core_deploy_app() {
    local app_id="${1}"
    local template_dir="${BASE_DIR}/templates/${app_id}"
    local target_dir="/opt/stacks/${app_id}"
    
    log_info "Iniciando despliegue de infraestructura para: ${app_id}..."

    # 1. Validación de origen
    if [[ ! -d "${template_dir}" ]]; then
        log_error "Directorio de plantillas no encontrado para ${app_id} en ${template_dir}"
        return 1
    fi

    # 2. Lectura de Metadatos
    local meta_file="${template_dir}/metadata.conf"
    if [[ -f "${meta_file}" ]]; then
        # shellcheck source=/dev/null
        source "${meta_file}"
        log_info "Procesando: ${APP_NAME:-$app_id} (Versión: ${VERSION:-Desconocida})"
    else
        log_warn "Archivo metadata.conf ausente en ${app_id}."
    fi

    # 3. Hook Pre-Instalación (Proceso aislado)
    if [[ -f "${template_dir}/pre_install.sh" ]]; then
        log_info "Ejecutando hook pre-instalación..."
        bash "${template_dir}/pre_install.sh" "${app_id}"
    fi

    # 4. Aprovisionamiento del directorio destino
    mkdir -p "${target_dir}"
    chmod 750 "${target_dir}"

    # 5. Plantillado y Clonación
    if [[ -f "${template_dir}/compose.yaml" ]]; then
        cp "${template_dir}/compose.yaml" "${target_dir}/compose.yaml"
    fi

    if [[ -f "${template_dir}/env.template" ]]; then
        log_info "Transmutando variables de entorno..."
        process_template "${template_dir}/env.template" "${target_dir}/.env"
    fi

    # 6. Hook Post-Instalación (Proceso aislado)
    if [[ -f "${template_dir}/post_install.sh" ]]; then
        log_info "Ejecutando hook post-instalación..."
        bash "${template_dir}/post_install.sh" "${app_id}" "${target_dir}"
    fi

    log_success "${app_id} empaquetado en ${target_dir}. Listo para ser adoptado por Dockge."
}
INNER

echo "✅ Motor de despliegue generado en lib/core/engine.sh"
rm implement_engine.sh
EOF

bash implement_engine.sh