#!/usr/bin/env bash
check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo -e "\e[31m[ERROR]\e[0m Este script debe ser ejecutado como root (usa sudo)."
        exit 1
    fi
}
