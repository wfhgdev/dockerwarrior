#!/usr/bin/env bash
# ==============================================================================
# DockerWarrior - Gestión de Redes Internas
# ==============================================================================

configure_dw_network() {
    log_info "Configurando red aislada de DockerWarrior..."

    # Comprobar si la red definida en defaults.conf ya existe
    if docker network inspect "${DW_NETWORK}" &> /dev/null; then
        log_success "La red Docker '${DW_NETWORK}' ya existe. Omitiendo creación."
    else
        docker network create \
            --driver bridge \
            --label project=dockerwarrior \
            "${DW_NETWORK}" > /dev/null
        log_success "Red interna '${DW_NETWORK}' creada exitosamente."
    fi
}