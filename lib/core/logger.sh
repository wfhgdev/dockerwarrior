#!/usr/bin/env bash
LOG_FILE="/var/log/dockerwarrior.log"

init_log_file() {
    touch "${LOG_FILE}"
    chmod 600 "${LOG_FILE}"
}

log_info() { echo -e "\e[34m[INFO]\e[0m $1" | tee -a "${LOG_FILE}"; }
log_success() { echo -e "\e[32m[OK]\e[0m $1" | tee -a "${LOG_FILE}"; }
log_warn() { echo -e "\e[33m[WARN]\e[0m $1" | tee -a "${LOG_FILE}"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $1" | tee -a "${LOG_FILE}"; }
