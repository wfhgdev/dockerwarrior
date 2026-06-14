#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core v1.0.1 - Subsistema de Reportes e Inventario (Fase 6.10)
# ==============================================================================
set -Eeuo pipefail

# Buffers globales en memoria para la persistencia del estado durante la ejecución
_DW_REP_HOST_BUFFER=""
_DW_REP_CORE_BUFFER=""
_DW_REP_PANEL_BUFFER=""
_DW_REP_APP_BUFFER=""
_DW_REP_REC_BUFFER=""
_DW_REP_REC_COUNT=1

report_init() {
    local fw_version="v1.0.1"
    local current_date
    current_date=$(date +"%Y-%m-%d %H:%M:%S")
    local host_name
    host_name=$(hostname)
    local target_os
    target_os=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"' || echo "Linux Server")
    local primary_ip
    primary_ip=$(hostname -I | awk '{print $1}' || echo "127.0.0.1")

    read -r -d '' _DW_REP_HOST_BUFFER << EOF || true
${TXT_REPORT_VERSION:-Versión del framework:} ${fw_version}
${TXT_REPORT_DATE:-Fecha y hora de instalación:} ${current_date}
${TXT_REPORT_HOST:-Host:} ${host_name} (IP: ${primary_ip})
${TXT_REPORT_OS:-Sistema operativo:} ${target_os} ($(uname -m))
EOF
}

report_register_core_service() {
    local service_name="${1}"
    local status="${2:-✓}"
    _DW_REP_CORE_BUFFER+="${status} ${service_name}"$'\n'
}

report_register_panel() {
    local panel_name="${1}"
    local panel_url="${2}"
    _DW_REP_PANEL_BUFFER+="${panel_name}:"$'\n'"${panel_url}"$'\n\n'
}

report_register_application() {
    local app_id="${1}"
    local apps_conf="${2:-config/apps.conf}"
    local app_name="${app_id}"
    local stack_path="/opt/stacks/${app_id}"
    local container_status="${TXT_REPORT_STATUS_PREP:-Preparado en Dockge}"

    # Buscar nombre legible en apps.conf sin añadir campos a metadata.conf
    if [[ -f "${apps_conf}" ]]; then
        local found_name
        found_name=$(grep "^${app_id}=" "${apps_conf}" | cut -d'=' -f2- || true)
        if [[ -n "${found_name}" ]]; then
            app_name="${found_name}"
        fi
    fi

    # Verificar existencia física en el directorio de producción único
    if [[ ! -d "${stack_path}" ]]; then
        return 0
    fi

    # Determinar el estado real de ejecución mediante inspección directa del daemon
    if command -v docker &>/dev/null; then
        # Comprobar si hay contenedores activos asociados al espacio de nombres del stack
        if docker ps --format '{{.Names}}' | grep -E "^${app_id}(-|_)" &>/dev/null; then
            container_status="${TXT_REPORT_STATUS_RUN:-En ejecución}"
        fi
    fi

    read -r -d '' tmp_app << EOF || true
${app_name}:
${TXT_REPORT_PATH:-Ruta:}
 ${stack_path}
${TXT_REPORT_STATUS_HEADER:-Estado:}
 ${container_status}

EOF
    _DW_REP_APP_BUFFER+="${tmp_app}"
}

report_add_recommendation() {
    local text="${1}"
    _DW_REP_REC_BUFFER+="  ${_DW_REP_REC_COUNT}. ${text}"$'\n'
    _DW_REP_REC_COUNT=$((_DW_REP_REC_COUNT + 1))
}

_report_build_payload() {
    cat << EOF
---------------------------------------------------
${TXT_REPORT_TITLE:-DockerWarrior Deployment Report}
---------------------------------------------------

${TXT_REPORT_GENERIC_INFO:-Información general:}
${_DW_REP_HOST_BUFFER}

${TXT_REPORT_CORE:-Infraestructura Base:}
${_DW_REP_CORE_BUFFER:-  No se han registrado servicios core.}
${TXT_REPORT_PANELS:-Paneles de Administración:}
${_DW_REP_PANEL_BUFFER:-  No se han registrado paneles.}
${TXT_REPORT_APPS:-Aplicaciones desplegadas:}
${_DW_REP_APP_BUFFER:-  Ninguna aplicación adicional detectada.}
${TXT_REPORT_RECOMMENDATIONS:-Pasos recomendados:}
${_DW_REP_REC_BUFFER:-  No hay recomendaciones específicas.}
EOF
}

report_generate_console() {
    _report_build_payload
}

report_generate_file() {
    local target_file="/opt/stacks/dockerwarrior-report.txt"
    local target_dir
    target_dir=$(dirname "${target_file}")

    if [[ ! -d "${target_dir}" ]]; then
        mkdir -p "${target_dir}"
    fi

    _report_build_payload > "${target_file}"
    chmod 600 "${target_file}"
}