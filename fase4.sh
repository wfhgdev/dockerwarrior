cat << 'EOF' > implement_phase4.sh
#!/usr/bin/env bash
set -Eeuo pipefail

echo "⚙️ Implementando archivos de la Fase 4 en $(pwd)..."

# 1. config/defaults.conf
cat << 'INNER' > config/defaults.conf
# Definición de rutas globales del sistema
STACKS_ROOT="/opt/stacks"
DOCKGE_ROOT="/opt/dockge"

# Configuración de red interna de DockerWarrior
DW_NETWORK="dw-routing"

# Puertos asignados por defecto a la infraestructura base
DOCKGE_PORT="5001"
PORTAINER_PORT="9443"
INNER

# 2. config/versions.conf
cat << 'INNER' > config/versions.conf
# Control centralizado de tags de imágenes Docker
VERSION_DOCKGE="1.4.2"
VERSION_PORTAINER="2.21.5"
VERSION_NPM="2.12.1"
VERSION_WGEASY="14.1.2"
VERSION_NEXTCLOUD="29.0.2"
VERSION_JELLYFIN="10.9.6"
VERSION_IMMICH="v1.106.1"
VERSION_ADGUARD="v0.107.52"
VERSION_VAULTWARDEN="1.31.0"
INNER

# 3. lib/docker/install.sh
cat << 'INNER' > lib/docker/install.sh
#!/usr/bin/env bash

install_docker_engine() {
    if command -v docker &> /dev/null; then
        log_success "Docker ya está instalado en el sistema: $(docker --version)"
        return 0
    fi

    log_info "Instalando dependencias previas de Docker..."
    apt-get update -qq
    apt-get install -y ca-certificates curl gnupg > /dev/null

    log_info "Configurando el llavero GPG oficial de Docker..."
    install -m 0755 -d /etc/apt/keyrings
    
    local os_id
    os_id=$(. /etc/os-release && echo "$ID")

    curl -fsSL "https://download.docker.com/linux/${os_id}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    chmod a+r /etc/apt/keyrings/docker.gpg

    log_info "Añadiendo el repositorio oficial a las fuentes de APT..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${os_id} \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    log_info "Instalando Docker Engine y Docker Compose Plugin..."
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null

    systemctl enable --now docker > /dev/null
    log_success "Docker Engine y Docker Compose instalados de forma segura."
}
INNER

# 4. lib/docker/network.sh
cat << 'INNER' > lib/docker/network.sh
#!/usr/bin/env bash

configure_dw_network() {
    log_info "Configurando red aislada de DockerWarrior..."

    if docker network inspect "${DW_NETWORK}" &> /dev/null; then
        log_success "La red Docker '${DW_NETWORK}' ya existe. Omitiendo creación."
    else
        docker network create --driver bridge --label project=dockerwarrior "${DW_NETWORK}" > /dev/null
        log_success "Red interna '${DW_NETWORK}' creada exitosamente."
    fi
}
INNER

# 5. apps/core/dockge.sh
cat << 'INNER' > apps/core/dockge.sh
#!/usr/bin/env bash

deploy_dockge() {
    log_info "Preparando el entorno de directorios para Dockge..."
    mkdir -p "${STACKS_ROOT}" "${DOCKGE_ROOT}"

    log_info "Generando manifiesto Compose para Dockge (Versión ${VERSION_DOCKGE})..."
    cat <<EOF > "${DOCKGE_ROOT}/compose.yaml"
services:
  dockge:
    image: louislam/dockge:\${VERSION_DOCKGE}
    container_name: dw-dockge
    restart: unless-stopped
    ports:
      - "${DOCKGE_PORT}:5001"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/app/data
      - ${STACKS_ROOT}:${STACKS_ROOT}
    environment:
      - DOCKGE_STACKS_DIR=${STACKS_ROOT}
networks:
  default:
    name: ${DW_NETWORK}
    external: true
EOF

    log_info "Lanzando el contenedor de Dockge..."
    cd "${DOCKGE_ROOT}"
    docker compose up -d > /dev/null
    log_success "Dockge desplegado correctamente en el puerto ${DOCKGE_PORT}."
}
INNER

# 6. apps/core/portainer.sh
cat << 'INNER' > apps/core/portainer.sh
#!/usr/bin/env bash

deploy_portainer() {
    local portainer_dir="${STACKS_ROOT}/portainer"
    log_info "Configurando el Stack de Portainer en la ruta de Dockge..."
    mkdir -p "${portainer_dir}"

    log_info "Generando manifiesto Compose para Portainer CE (Versión ${VERSION_PORTAINER})..."
    cat <<EOF > "${portainer_dir}/compose.yaml"
services:
  portainer:
    image: portainer/portainer-ce:\${VERSION_PORTAINER}
    container_name: dw-portainer
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    ports:
      - "${PORTAINER_PORT}:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/data
networks:
  default:
    name: ${DW_NETWORK}
    external: true
EOF

    log_info "Lanzando el Stack de Portainer..."
    cd "${portainer_dir}"
    docker compose up -d > /dev/null
    log_success "Portainer CE desplegado correctamente (HTTPS) en el puerto ${PORTAINER_PORT}."
}
INNER

# 7. Sobrescribir install.sh con la integración final de la Fase 4
cat << 'INNER' > install.sh
#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${BASE_DIR}/lib/core/logger.sh"
source "${BASE_DIR}/lib/core/utils.sh"
source "${BASE_DIR}/lib/core/system.sh"
source "${BASE_DIR}/config/defaults.conf"
source "${BASE_DIR}/config/versions.conf"
source "${BASE_DIR}/lib/docker/install.sh"
source "${BASE_DIR}/lib/docker/network.sh"
source "${BASE_DIR}/apps/core/dockge.sh"
source "${BASE_DIR}/apps/core/portainer.sh"

error_handler() {
    local exit_code="${1}"
    local line_number="${2}"
    log_error "El proceso falló inesperadamente en la línea ${line_number} con código de salida ${exit_code}."
    log_error "Revisa el registro completo en: \${LOG_FILE}"
    exit "${exit_code}"
}

trap 'error_handler \$? \$LINENO' ERR

main() {
    clear
    echo "======================================================================"
    echo "                 🛡️  BIENVENIDO A DOCKERWARRIOR 🛡️"
    echo "======================================================================"
    echo ""
    
    check_root
    init_log_file
    
    log_info "Iniciando secuencia de verificación del entorno..."
    validate_os
    validate_architecture
    validate_hardware
    validate_required_packages
    
    log_success "El entorno base cumple con todos los requisitos."
    echo ""

    log_info "Iniciando despliegue de la infraestructura de contenedores..."
    install_docker_engine
    configure_dw_network
    
    log_info "Instalando interfaces de administración web..."
    deploy_dockge
    deploy_portainer

    echo ""
    log_success "======================================================================"
    log_success " 🎉 ¡ENTORNO CORE DESPLEGADO CON ÉXITO! 🎉"
    log_success "======================================================================"
    log_success "  ➜ Dockge (HTTP):  http://localhost:${DOCKGE_PORT}"
    log_success "  ➜ Portainer (HTTPS): https://localhost:${PORTAINER_PORT}"
    log_success "======================================================================"
    echo ""
}

main "\$@"
INNER

echo "✅ Todos los archivos de la Fase 4 han sido escritos. Eliminando instalador temporal..."
rm implement_phase4.sh
EOF
bash implement_phase4.sh