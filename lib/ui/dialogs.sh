#!/usr/bin/env bash

ui_message() {
    local title="${1}"
    local text="${2}"
    whiptail --title "${title}" --msgbox "${text}" 12 65
}

ui_confirm() {
    local title="${1}"
    local text="${2}"
    if whiptail --title "${title}" --yesno "${text}" 12 65 \
        --yes-button "${MSG_BTN_OK:-Yes}" --no-button "${MSG_BTN_CANCEL:-No}"; then
        return 0
    else
        return 1
    fi
}

ui_checklist() {
    local title="${1}"
    local text="${2}"
    shift 2
    local options=("$@")
    
    whiptail --title "${title}" --checklist "${text}" 22 80 12 "${options[@]}" 3>&1 1>&2 2>&3
}
