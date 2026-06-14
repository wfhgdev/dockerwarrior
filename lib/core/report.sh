#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior Core - Motor de Generación de Informes de Despliegue
# ==============================================================================
set -Eeuo pipefail

# Buffers globales en memoria para la consolidación del reporte
DW_REPORT_HOST_INFO=""
DW_REPORT_CORE_SERVICES=""
DW_REPORT_PANELS=""
DW_REPORT_APPLICATIONS=""
DW_REPORT_RECOMMENDATIONS=""

report_init() {
    local dw_version="${1:-v1.0.0}"
    local appspec_version="${2:-v1.1}"
    local install_id
    install_id=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | cut -d'-' -f1 || echo "DW-$(date +%s)")
    
    local current_date
    current_date=$(date +"%Y-%m-%d %H:%M:%S")
    local primary_ip
    primary_ip=$(hostname -I | awk '{print $1}' || echo "127.0.0.1")
    local os_info
    os_info=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"' || echo "Ubuntu Server")

    read -r -d '' DW_REPORT_HOST_INFO << EOF || true
${TXT_REPORT_DATE} ${current_date}
Installation ID: ${install_id}
DockerWarrior Version: ${dw_version}
DW-AppSpec Version: ${appspec_version}
---------------------------------------------------------
Hostname:     $(hostname)
Primary IP:   ${primary_ip}
OS Target:    ${os_info}
Architecture: $(uname -m)
EOF
}

report_add_core_service() {
    local service_name="${1}"
    local status="${2:-Instalado/Reutilizado}"
    DW_REPORT_CORE_SERVICES+=$'\n'粉"  ✓ ${service_name} (${status})"
}

report_add_panel() {
    local panel_name="${1}"
    local access_url="${2}"
    DW_REPORT_PANELS+=$'\n'"  ✓ ${panel_name}"$'\n'"    URL: ${access_url}"$'\n'
}

report_add_application() {
    local app_name="${1}"
    local stack_path="${2}"
    local access_url="${3}"
    local status="${4}"
    
    read -r -d '' tmp_app << EOF || true
  • ${app_name}
    Ubicación del Stack: ${stack_path}
    URL Esperada:        ${access_url}
    Estado:              ${status}

EOF
    DW_REPORT_APPLICATIONS+="${tmp_app}"$'\n'
}

report_add_recommendation() {
    local index="${1}"
    local description="${2}"
    DW_REPORT_RECOMMENDATIONS+=$'\n'"  ${index}. ${description}"
}

_report_build_payload() {
    cat << EOF
${TXT_REPORT_BANNER}
${TXT_REPORT_TITLE}
${TXT_REPORT_BANNER}

== ${TXT_REPORT_HOST} ==
${DW_REPORT_HOST_INFO}

== ${TXT_REPORT_CORE} ==
${DW_REPORT_CORE_SERVICES:-  No se registraron cambios en esta sesión.}

== ${TXT_REPORT_PANELS} ==
${DW_REPORT_PANELS:-  No se modificaron paneles de control.}

== ${TXT_REPORT_STACKS} ==
${DW_REPORT_APPLICATIONS:-  Ninguna aplicación adicional desplegada.}

== ${TXT_REPORT_SECRETS} ==
  * ${TXT_REPORT_SEC_NOTICE}
    /opt/stacks/<app_id>/.env
  * ${TXT_REPORT_SEC_PERMS} 600 (root-only)
  
  ! ${TXT_REPORT_SEC_WARN}

== ${TXT_REPORT_NEXT_STEPS} ==
${DW_REPORT_RECOMMENDATIONS:-  Verificar el estado general del sistema mediante CLI.}

=========================================================
${TXT_REPORT_COMPLETED}
=========================================================
EOF
}

report_generate_console() {
    echo -e "\n"
    _report_build_payload
    echo -e "\n"
}

report_generate_file() {
    local target_dir="/opt/dockerwarrior"
    local target_file="${target_dir}/deployment-report.txt"
    
    if [[ ! -d "${target_dir}" ]]; then
        mkdir -p "${target_dir}" 2>/dev/null || {
            log_error "${TXT_REPORT_ERR_DIR}" >&2
            return 1
        }
    fi
    
    _report_build_payload > "${target_file}"
    chmod 600 "${target_file}"
    return 0
}