#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior - Orquestador Principal de Instalación (Core v1.3.1-RC2)
# ==============================================================================
set -Eeuo pipefail

# --- 0. CONTROL DE PRIVILEGIOS NATIVO (PRE-CHECKS ABSOLUTO) ---
if [[ "${EUID}" -ne 0 ]]; then
    echo -e "\e[31m[ERROR]\e[0m Este script debe ejecutarse con privilegios de root (sudo)." >&2
    exit 1
fi

# --- 1. CONTROL DE EXCEPCIONES GLOBAL ---
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

# --- 2. CONFIGURACIÓN DEL ENTORNO RAÍZ Y ENRUTAMIENTO ---
export BASE_DIR
BASE_DIR=$(dirname "$(readlink -f "$0")")
cd "${BASE_DIR}"

# --- 3. CONSTANTES GLOBALES DEL FRAMEWORK ---
export DW_VERSION="v1.3.1-RC2"
export DW_APPSPEC_VERSION="v1.1"
export DW_CORE_DIR="/opt/dockerwarrior"
export DW_STACKS_DIR="/opt/stacks"

# --- 4. CARGA DE LIBRERÍAS, CONFIGURACIONES Y COMPONENTES CORE ---
source "lib/core/logger.sh"
source "lib/core/system.sh"
source "lib/core/engine.sh"
source "lib/docker/network.sh"
source "lib/docker/install.sh"
source "lib/core/report.sh"
source "lib/ui/dialogs.sh"
source "lib/ui/menu.sh"

# Ingesta opcional de configuraciones globales por defecto si existen
if [[ -f "config/defaults.conf" ]]; then
    # shellcheck disable=SC1091
    source "config/defaults.conf"
fi

# Definición unificada de la red (Prioriza config/defaults.conf -> fallback seguro)
export DW_NETWORK="${DW_NETWORK:-dw-routing}"

# Inicializar de forma segura el archivo de log ahora que la firma de root está validada
init_log_file

# --- [MEJORA DE FLUJO] VALIDACIÓN TEMPRANA DEL HOST ---
# Validamos el entorno antes de intentar cualquier instalación por APT (como whiptail)
validate_os
validate_architecture

# --- 5. GESTIÓN SEGURA DE INTERNACIONALIZACIÓN (i18n) ---
export LANG_SELECTED="${LANG_SELECTED:-}"

if [[ -z "${LANG_SELECTED}" ]]; then
    if [[ -t 0 ]]; then
        # Verificar y auto-aprovisionar whiptail de forma reactiva si falta en el host
        if ! command -v whiptail &>/dev/null; then
            log_info "Componente de interfaz gráfica 'whiptail' ausente. Instalando dependencia..." 
            apt-get update -qq && apt-get install -y whiptail >/dev/null 2>&1 || true
        fi

        # Despliegue balanceado del menú interactivo o desvío a interfaz nativa por consola
        if command -v whiptail &>/dev/null; then
            LANG_CHOICE=$(whiptail --title "DockerWarrior Core Engine" \
                --menu "Seleccione su idioma / Select your language:" 11 55 2 \
                "1" "Español (es)" \
                "2" "English (en)" \
                3>&1 1>&2 2>&3) || LANG_CHOICE="1"
            
            if [[ "${LANG_CHOICE}" == "2" ]]; then
                LANG_SELECTED="en"
            else
                LANG_SELECTED="es"
            fi
        else
            # Fallback robusto en texto plano por si los repositorios apt estuvieran bloqueados
            echo -e "\n--- DockerWarrior Idioma / Language ---"
            echo "1) Español (es)"
            echo "2) English (en)"
            read -rp "Seleccione una opción [1]: " lang_raw
            [[ "${lang_raw}" == "2" ]] && LANG_SELECTED="en" || LANG_SELECTED="es"
        fi
    else
        # Modo desatendido / TTY aislado: Auto-detección por variables de entorno local
        if [[ -n "${LANG:-}" ]]; then
            LANG_SELECTED="${LANG%%_*}"
        fi
        if [[ "${LANG_SELECTED}" != "es" && "${LANG_SELECTED}" != "en" ]]; then
            LANG_SELECTED="es"
        fi
    fi
fi

# Cargar de forma segura los diccionarios idiomáticos compilados
if [[ -f "lang/${LANG_SELECTED}.sh" ]]; then
    # shellcheck disable=SC1091
    source "lang/${LANG_SELECTED}.sh"
else
    # Fallback interno de contingencia lingüística
    export MSG_MENU_TITLE="DockerWarrior - Catálogo de Aplicaciones"
    export MSG_MENU_TEXT="Utilice la BARRA ESPACIADORA para marcar. Presione ENTER para confirmar."
fi

# --- 6. FLUJO PRINCIPAL DE DESPLIEGUE (MAIN EXECUTION) ---
main() {
    log_info "========================================================="
    log_info " Iniciando Despliegue de Infraestructura DockerWarrior"
    log_info "========================================================="

    # Fase 1: Aprovisionamiento del motor de contenedores en caliente
    log_info "Fase 1: Verificando estado del motor de contenedores..."
    if ! command -v docker &>/dev/null || ! docker compose version &>/dev/null; then
        log_warn "Docker Engine o Docker Compose no detectados. Iniciando aprovisionamiento..."
        install_docker_engine
    else
        log_success "Docker Engine instalado correctamente: $(docker --version)"
        log_success "Docker Compose V2 detectado y operativo."
    fi

    # Fase 2: Construcción de redes de aislamiento perimetral
    log_info "Fase 2: Configurando redes globales segmentadas..."
    if command -v configure_dw_network &>/dev/null; then
        configure_dw_network
    else
        # Red de contingencia utilizando la variable unificada dinámica
        if ! docker network inspect "${DW_NETWORK}" &>/dev/null; then
            log_info "Creando red global aislada '${DW_NETWORK}'..."
            docker network create --driver bridge --label project=dockerwarrior "${DW_NETWORK}" >/dev/null
            log_success "Red '${DW_NETWORK}' creada con éxito."
        fi
    fi

    # Fase 3: Despliegue de los paneles administrativos del Núcleo (Core Stacks)
    log_info "Fase 3: Desplegando paneles de administración core..."
    
    # Orquestador Visual Dockge
    if command -v install_dockge &>/dev/null; then
        install_dockge
    fi

    # Administrador de Contenedores Portainer CE
    if command -v install_portainer &>/dev/null; then
        install_portainer
    fi

    # Fase 4: Catálogo y selección dinámica de Microservicios adicionales
    log_info "Fase 4: Selección de aplicaciones adicionales..."
    local selected_apps=""

    if [[ -t 0 ]]; then
        # Entorno Interactivo: Renderizar checklist Whiptail
        if command -v ui_select_apps &>/dev/null; then
            selected_apps=$(ui_select_apps) || selected_apps=""
        fi
    else
        # Entorno Desatendido / TTY No disponible
        log_warn "Terminal no interactiva detectada. Omitiendo interfaz visual de catálogo de forma automatizada."
    fi

    # Despliegue iterativo a través del Motor Declarativo Estándar
    if [[ -n "${selected_apps}" ]]; then
        for app_id in ${selected_apps}; do
            log_info "Procesando e instalando servicio del catálogo: ${app_id}"
            if command -v deploy_app &>/dev/null; then
                if deploy_app "${app_id}"; then
                    log_success "Módulo '${app_id}' desplegado e inyectado con éxito."
                else
                    log_error "Fallo durante el despliegue del stack: ${app_id}"
                fi
            fi
        done
    else
        log_info "No se seleccionaron aplicaciones adicionales para desplegar."
    fi

    # Fase 5: Consolidación, Auditoría e Ingesta de Inventario de Sistemas
    log_info "Fase 5: Consolidando métricas y guardando inventario de infraestructura..."
    
    # Inicializar buffers de memoria del reporte técnico
    if command -v report_init &>/dev/null; then
        report_init
        
        # Mapear de forma agnóstica el estado real de los contenedores levantados
        [[ -f "/opt/dockge/compose.yaml" ]] && report_add_core_panel "Dockge" "http://$(hostname -I | awk '{print $1}'):5001" "/opt/dockge"
        docker ps -q -f name=^/portainer$ &>/dev/null && report_add_core_panel "Portainer CE" "https://$(hostname -I | awk '{print $1}'):9443" "Docker Volume"
    fi

    # Inyección dinámica de las recomendaciones operativas i18n
    report_add_recommendation "${TXT_REC_STEP_1:-Acceder a Dockge y levantar los stacks preparados.}"
    report_add_recommendation "${TXT_REC_STEP_2:-Inicializar la cuenta administrativa de Portainer.}"
    report_add_recommendation "${TXT_REC_STEP_3:-Verificar contenedores con: sudo docker ps}"
    report_add_recommendation "${TXT_REC_STEP_4:-Verificar permisos de secretos con: sudo ls -l /opt/stacks/*/.env}"

    # Escritura e impresión del reporte de infraestructura persistente
    if report_generate_file &>/dev/null; then
        log_success "Reporte de despliegue almacenado correctamente."
    else
        log_warn "No fue posible guardar el reporte persistente de instalación."
    fi

    # Renderizado final en la STDOUT estándar para lectura del operador
    echo
    report_generate_console
    echo

    log_success "========================================================="
    log_success " DockerWarrior ha finalizado la instalación correctamente "
    log_success "========================================================="

    return 0
}

# Invocación limpia del punto de entrada estructurado del Framework
main "$@"