#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior - Orquestador Principal de Instalación (Core v1.0.3)
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
export DW_VERSION="v1.0.3"
export DW_APPSPEC_VERSION="v1.1"
export DW_CORE_DIR="/opt/dockerwarrior"
export DW_STACKS_DIR="/opt/stacks"


# --- INTERNACIONALIZACIÓN (i18n) ---
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
if [[ -f "lib/core/logger.sh" ]]; then
    source "lib/core/logger.sh"
else
    echo "[ERR] lib/core/logger.sh ausente." >&2
    exit 1
fi


if [[ -f "lib/core/system.sh" ]]; then
    source "lib/core/system.sh"
else
    echo "[ERR] lib/core/system.sh ausente." >&2
    exit 1
fi


if [[ -f "lib/docker/install.sh" ]]; then
    source "lib/docker/install.sh"
else
    echo "[ERR] lib/docker/install.sh ausente." >&2
    exit 1
fi


if [[ -f "lib/core/engine.sh" ]]; then
    source "lib/core/engine.sh"
else
    echo "[ERR] lib/core/engine.sh ausente." >&2
    exit 1
fi


if [[ -f "lib/core/report.sh" ]]; then
    source "lib/core/report.sh"
else
    echo "[ERR] lib/core/report.sh ausente." >&2
    exit 1
fi


# --- NUEVA CAPA DE INTERFAZ DE USUARIO ---
if [[ -f "lib/ui/dialogs.sh" ]]; then
    source "lib/ui/dialogs.sh"
else
    echo "[ERR] lib/ui/dialogs.sh ausente." >&2
    exit 1
fi


if [[ -f "lib/ui/menu.sh" ]]; then
    source "lib/ui/menu.sh"
else
    echo "[ERR] lib/ui/menu.sh ausente." >&2
    exit 1
fi


# --- APLICACIONES CORE ---
if [[ -f "apps/core/dockge.sh" ]]; then
    source "apps/core/dockge.sh"
else
    echo "[ERR] apps/core/dockge.sh ausente." >&2
    exit 1
fi


if [[ -f "apps/core/portainer.sh" ]]; then
    source "apps/core/portainer.sh"
else
    echo "[ERR] apps/core/portainer.sh ausente." >&2
    exit 1
fi

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
        log_warn "Docker Engine no detectado. Procediendo con el aprovisionamiento automatizado..."

    if install_docker_engine; then
        log_success "Docker Engine instalado correctamente."
        report_add_core_service "Docker Engine" "✓ (Instalado)"
    else
        log_error "La instalación automática de Docker Engine ha fallado."
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
    if install_dockge; then
       report_add_panel "Dockge" "http://${host_ip}:5001"
    else
       log_error "No fue posible desplegar Dockge."
    fi

    # Aprovisionamiento del Panel 2: Portainer CE
    if install_portainer; then
       report_add_panel "Portainer CE" "https://${host_ip}:9443"
    else
       log_error "No fue posible desplegar Portainer CE."
    fi

    # 4. Procesamiento Dinámico del Catálogo de Aplicaciones
    log_info "Fase 4: Selección de aplicaciones adicionales..."

    local selected_apps=""
    local ui_status=0

    # Mostrar interfaz Whiptail para selección de aplicaciones
    selected_apps=$(ui_select_apps) || ui_status=$?

    case "${ui_status}" in
        0)
            log_info "Selección de aplicaciones completada correctamente."
            ;;

        3)
            log_warn "El usuario canceló la selección de aplicaciones. Continuando con la instalación base."
            selected_apps=""
            ;;

        *)
            log_error "Error en la interfaz de selección de aplicaciones."
            exit 1
            ;;
    esac


    # Construir lista de aplicaciones a desplegar
    local apps_to_deploy=()

    if [[ -n "${selected_apps}" ]]; then
        read -r -a apps_to_deploy <<< "${selected_apps}"
    fi


    # Verificación de seguridad: evitar despliegues con identificadores inválidos
    for app_id in "${apps_to_deploy[@]}"; do
        if [[ ! "${app_id}" =~ ^[a-z0-9_-]+$ ]]; then
            log_error "Identificador de aplicación inválido detectado: ${app_id}"
            exit 1
        fi
    done


    # Procesamiento del catálogo seleccionado
    local catalog_file="config/apps.conf"

    if [[ ${#apps_to_deploy[@]} -eq 0 ]]; then
        log_info "No se seleccionaron aplicaciones adicionales para desplegar."
    else

        log_info "Iniciando despliegue de aplicaciones seleccionadas..."

        for app_id in "${apps_to_deploy[@]}"; do

            if [[ -d "templates/${app_id}" ]]; then

                log_info "Procesando despliegue e inyección de entorno para: ${app_id}"

                if core_deploy_app "${app_id}"; then

                    log_success "Estructura del stack '${app_id}' desplegada correctamente."

                    report_add_application "${app_id}" "${BASE_DIR}/${catalog_file}"

                else

                    log_error "Fallo durante el despliegue del stack: ${app_id}"

                fi

            else

                log_error "El paquete '${app_id}' no existe en la carpeta de plantillas."

            fi

        done

    fi
    # 5. Inyección de Recomendaciones Operativas i18n
    report_add_recommendation "${TXT_REC_STEP_1:-Acceder a Dockge y levantar los stacks preparados.}"
    report_add_recommendation "${TXT_REC_STEP_2:-Inicializar la cuenta administrativa de Portainer.}"
    report_add_recommendation "${TXT_REC_STEP_3:-Verificar contenedores con: sudo docker ps}"
    report_add_recommendation "${TXT_REC_STEP_4:-Verificar permisos de secretos con: sudo ls -l /opt/stacks/*/.env}"

    # 6. Consolidación y generación del inventario final
    log_info "Fase 5: Consolidando métricas y guardando inventario de infraestructura..."

    # Generación del reporte persistente en disco
    if report_generate_file; then
        log_success "Reporte de despliegue almacenado correctamente."
    else
        log_warn "No fue posible guardar el reporte persistente de instalación."
    fi


    # Mostrar resumen final por consola
    echo
    report_generate_console
    echo


    log_success "========================================================="
    log_success " DockerWarrior ha finalizado la instalación correctamente "
    log_success "========================================================="

    return 0
}


# --- Punto de entrada principal ---
main "$@"