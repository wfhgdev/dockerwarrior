#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core v1.0.1 - Subsistema de Reportes e Inventario (Fase 6.10 Final)
# ==============================================================================
set -Eeuo pipefail

# Buffers globales en memoria para la acumulación estructurada de datos
_DW_REP_HOST_BUFFER=""
_DW_REP_CORE_BUFFER=""
_DW_REP_PANEL_BUFFER=""
_DW_REP_APP_BUFFER=""
_DW_REP_REC_BUFFER=""
_DW_REP_REC_COUNT=1

report_init() {
    # Capturar versiones globales inyectadas desde el orquestador principal
    local core_ver="${DW_VERSION:-v1.0.1}"
    local appspec_ver="${DW_APPSPEC_VERSION:-v1.1}"
    
    # Recopilación dinámica y en caliente de métricas del entorno del host
    local current_date
    current_date=$(date +"%Y-%m-%d %H:%M:%S")
    local host_name
    host_name=$(hostname)
    local primary_ip
    primary_ip=$(hostname -I | awk '{print $1}' || echo "127.0.0.1")
    local os_target
    os_target=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"' || echo "Linux Server")
    local host_arch
    host_arch=$(uname -m)

    # CORRECCIÓN 1: Eliminación radical de textos en inglés hardcodeados
    read -r -d '' _DW_REP_HOST_BUFFER << EOF || true
${TXT_REPORT_FRAMEWORK:-Framework}:
  ✓ DockerWarrior Core ${core_ver}
  ✓ DW-AppSpec ${appspec_ver}

${TXT_REPORT_HOST:-Servidor}:
  ${os_target}
  ${TXT_REPORT_HOSTNAME:-Nombre del host}: ${host_name}
  ${TXT_REPORT_IP:-Dirección IP}: ${primary_ip}
  ${TXT_REPORT_ARCH:-Arquitectura}: ${host_arch}
EOF
}

report_add_core_service() {
    local service_name="${1}"
    local status="${2:-✓}"
    _DW_REP_CORE_BUFFER+="  ${status} ${service_name}"$'\n'
}

report_add_panel() {
    local panel_name="${1}"
    local panel_url="${2}"
    _DW_REP_PANEL_BUFFER+="${panel_name}:"$'\n'"  ${panel_url}"$'\n\n'
}

report_add_application() {
    local app_id="${1}"
    local apps_conf="${2:-config/apps.conf}"
    local stack_path="/opt/stacks/${app_id}"
    local app_name="${app_id}"
    local container_status="${TXT_REPORT_STATUS_PREP:-Prepared in Dockge}"

    # Corrección de lectura usando el formato delimitado por tuberías |
    if [[ -f "${apps_conf}" ]]; then
        local found_name
        found_name=$(awk -F'|' -v id="${app_id}" '$1 == id {print $2}' "${apps_conf}" 2>/dev/null || true)
        if [[ -n "${found_name}" ]]; then
            app_name="${found_name}"
        fi
    fi

    # Si la aplicación no tiene un directorio físico desplegado, omitimos su registro
    if [[ ! -d "${stack_path}" ]]; then
        return 0
    fi

    # Inspección en caliente del estado del daemon de Docker
    if command -v docker &>/dev/null; then
        if docker ps --format '{{.Names}}' | grep -E "^${app_id}(-|_)" &>/dev/null; then
            container_status="${TXT_REPORT_STATUS_RUN:-Running}"
        fi
    fi

    read -r -d '' tmp_app << EOF || true
${app_name}:
  Path:
    ${stack_path}
  Status:
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

${TXT_REPORT_HEADER_GEN:-Información general:}
${_DW_REP_HOST_BUFFER}

${TXT_REPORT_HEADER_CORE:-Infraestructura Base:}
${_DW_REP_CORE_BUFFER:-  No se detectaron servicios core activos.}
${TXT_REPORT_HEADER_PANELS:-Paneles de Administración:}
${_DW_REP_PANEL_BUFFER:-  No se detectaron paneles activos.}
${TXT_REPORT_HEADER_APPS:-Aplicaciones desplegadas:}
${_DW_REP_APP_BUFFER:-  Ninguna aplicación adicional desplegada.}
${TXT_REPORT_HEADER_REC:-Pasos recomendados:}
${_DW_REP_REC_BUFFER:-  No hay recomendaciones operativas pendientes.}
EOF
}

report_generate_console() {
    _report_build_payload
}

report_generate_file() {
    local target_dir="/opt/dockerwarrior/reports"
    local target_file="${target_dir}/deployment-report.txt"

    if [[ ! -d "${target_dir}" ]]; then
        mkdir -p "${target_dir}"
    fi

    _report_build_payload > "${target_file}"
    chmod 640 "${target_file}"
}