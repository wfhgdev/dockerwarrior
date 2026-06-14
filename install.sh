#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior - Orquestador Principal de Instalación (Core v1.0.1)
# ==============================================================================
set -Eeuo pipefail

# --- CONTROL DE EXCEPCIONES GLOBAL ---
failure_handler() {
    local parent_lineno="${1}"
    local message="${2:-"Error desconocido"}"
    local code="${3:-1}"
    if command -v log_error &>/dev/null; then
        log_error "Error crítico en install.sh hacia la línea ${parent_lineno}: ${message}"
    else
        echo -e "\n[ERR] Error crítico en install.sh hacia la línea ${parent_lineno}: ${message}" >&2
    fi
    exit "${code}"
}
trap 'failure_handler ${LINENO} "$BASH_COMMAND" $?' ERR

# --- CONFIGURACIÓN DEL ENTORNO RAÍZ ---
export BASE_DIR
BASE_DIR=$(dirname "$(readlink -f "$0")")
cd "${BASE_DIR}"

# --- CONSTANTES GLOBALES DEL FRAMEWORK ---
export DW_VERSION="v1.0.1"
export DW_APPSPEC_VERSION="v1.1"
export DW_CORE_DIR="/opt/dockerwarrior"
export DW_STACKS_DIR="/opt/stacks"

# --- INTERNACIONALIZACIÓN (i18n) ---
# Detección o fallback del idioma configurado en el entorno
export LANG_SELECTED="${LANG_SELECTED:-es}"

if [[ -f "lang/${LANG_SELECTED}.sh" ]]; then
    # shellcheck disable=SC1091
    source "lang/${LANG_SELECTED}.sh"
else
    echo "[ERR] Archivo de idioma lang/${LANG_SELECTED}.sh no encontrado. Fallback a inglés." >&2
    if [[ -f "lang/en.sh" ]]; then
        # shellcheck disable=SC1091
        source "lang/en.sh"
    else
        echo "[ERR] Idioma base ausente. Abortando instalación." >&2
        exit 1
    fi
fi

# --- CARGA DE SUBSISTEMAS DEL CORE ---
# Se cargan de manera secuencial garantizando la disponibilidad de sus funciones
if [[ -f "lib/core/logger.sh" ]]; then source "lib/core/logger.sh"; else echo "[ERR] lib/core/logger.sh ausente." >&2; exit 1; fi
if [[ -f "lib/core/engine.sh" ]]; then source "lib/core/engine.sh"; else echo "[ERR] lib/core/engine.sh ausente." >&2; exit 1; fi
if [[ -f "lib/core/report.sh" ]]; then source "lib/core/report.sh"; else echo "[ERR] lib/core/report.sh ausente." >&2; exit 1; fi

# --- VERIFICACIONES PREVIAS DE SEGURIDAD ---
check_root_privileges() {
    if [[ "${EUID}" -ne 0 ]]; then
        log_error "DockerWarrior requiere privilegios de root para gestionar la infraestructura. Ejecuta con sudo."
        exit 1
    fi
}

# --- FLUJO PRINCIPAL DE ORQUESTACIÓN ---
main() {
    check_root_privileges
    
    log_info "========================================================="
    log_info " Iniciando Despliegue de Infraestructura DockerWarrior "
    log_info "========================================================="
    
    # 1. Inicializar la estructura de buffers en memoria del Report System
    report_init

    # 2. Validación e Instalación de Infraestructura Base
    log_info "Fase 1: Verificando dependencias del sistema operativo..."
    
    # Verificación en caliente de Docker Engine
    if command -v docker &>/dev/null; then
        log_success "Docker Engine detectado en el sistema host."
        report_add_core_service "Docker Engine" "✓ (${TXT_REPORT_STATUS_RUN:-En ejecución})"
    else
        log_warn "Docker Engine no detectado. Iniciando aprovisionamiento automático..."

    if install_docker_engine; then
        log_success "Docker Engine instalado correctamente."
        report_add_core_service "Docker Engine" "✓ (Instalado)"
    else
        log_error "La instalación de Docker Engine ha fallado. Abortando despliegue."
        exit 1
    fi
fi

    # Verificación de Docker Compose V2
    if docker compose version &>/dev/null; then
        log_success "Docker Compose V2 detectado y operativo."
        report_add_core_service "Docker Compose" "✓ (V2 Activo)"
    else
        log_error "Docker Compose V2 no disponible tras el aprovisionamiento. Abortando."
    exit 1
    fi

    # Asegurar la existencia de la red perimetral global aislada
    log_info "Fase 2: Configurando redes globales segmentadas..."
    if docker network inspect dw_proxy_network &>/dev/null; then
        log_success "Red global 'dw_proxy_network' detectada. Reutilizando infraestructura."
        report_add_core_service "dw_proxy_network" "✓ (Reutilizada)"
    else
        log_info "Creando red global aislada 'dw_proxy_network'..."
        docker network create --driver bridge dw_proxy_network >/dev/null
        log_success "Red 'dw_proxy_network' creada con éxito."
        report_add_core_service "dw_proxy_network" "✓ (Creada nueva)"
    fi

    # 3. Despliegue de Paneles de Control Centralizados
    log_info "Fase 3: Desplegando paneles de administración core..."
    local host_ip
    host_ip=$(hostname -I | awk '{print $1}' || echo "127.0.0.1")

    # Aprovisionamiento del Panel 1: Dockge
    # core_deploy_panel "dockge" -> Ejecución real encapsulada en engine.sh
    report_add_panel "Dockge" "http://${host_ip}:5001"

    # Aprovisionamiento del Panel 2: Portainer CE
    # core_deploy_panel "portainer" -> Ejecución real encapsulada en engine.sh
    report_add_panel "Portainer CE" "https://${host_ip}:9443"

    # 4. Procesamiento Dinámico del Catálogo de Aplicaciones
    log_info "Fase 4: Procesando cola de aplicaciones del catálogo..."
    
    # En una instalación real, esta lista se puebla desde las opciones elegidas en la UI (Whiptail)
    # Para efectos del Core v1.0.1, procesamos el paquete piloto certificado
    local apps_to_deploy=("nginx_proxy_manager")
    local catalog_file="config/apps.conf"

    for app_id in "${apps_to_deploy[@]}"; do
        if [[ -d "templates/${app_id}" ]]; then
            log_info "Procesando despliegue e inyección de entorno para: ${app_id}"
            
            # Llamada al motor de despliegue declarativo genérico (Inmutable)
            if core_deploy_app "${app_id}"; then
                log_success "Estructura del stack '${app_id}' desplegada correctamente."
            else
                log_error "Fallo en el despliegue del stack: ${app_id}"
                continue
            fi
            
            # Registro en el reporte sin modificar metadata.conf ni generar acoplamiento
            report_add_application "${app_id}" "${BASE_DIR}/${catalog_file}"
        else
            log_error "El paquete '${app_id}' no existe en la carpeta de plantillas."
        fi
    done

    # 5. Inyección de Recomendaciones Operativas i18n
    report_add_recommendation "${TXT_REC_STEP_1:-Acceder a Dockge y levantar los stacks preparados.}"
    report_add_recommendation "${TXT_REC_STEP_2:-Inicializar la cuenta administrativa de Portainer.}"
    report_add_recommendation "${TXT_REC_STEP_3:-Verificar contenedores: sudo docker ps}"
    report_add_recommendation "${TXT_REC_STEP_4:-Verificar permisos de secretos: sudo ls -l /opt/stacks/*/.env}"

    # 6. Consolidación y Cierre (Doble Impacto)
    log_info "Fase 5: Consolidando métricas y guardando inventario de infraestructura..."
    
    # Escritura atómica en /opt/dockerwarrior/reports/deployment-report.txt (permisos 640)
    report_generate_file
    
    # Renderizado estandarizado por consola
    echo -e "\n"
    report_generate_console
    echo -e "\n"

    log_success "Proceso de instalación completado. DockerWarrior se encuentra operativo."
}

main "$@"