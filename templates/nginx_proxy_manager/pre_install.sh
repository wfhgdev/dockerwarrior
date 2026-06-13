#!/usr/bin/env bash
set -Eeuo pipefail

NETWORK_NAME="npm_network"

echo "[HOOK] Verificando red externa: ${NETWORK_NAME}..."

# Validar idempotencia: Solo crear si no existe
if ! docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
    echo "[HOOK] Creando red Docker puente: ${NETWORK_NAME}"
    docker network create "${NETWORK_NAME}"
else
    echo "[HOOK] La red ${NETWORK_NAME} ya existe. Omitiendo creación."
fi

exit 0
