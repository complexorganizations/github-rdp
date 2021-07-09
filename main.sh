#!/bin/bash
# https://github.com/complexorganizations/github-codespaces-rdp

# Require script to be run as root
function super-user-check() {
    if [ "${EUID}" -ne 0 ]; then
        echo "You need to run this script as super user."
        exit
    fi
}

# Check for root
super-user-check

# Detect Operating System
function dist-check() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO=${ID}
    fi
}

# Check Operating System
dist-check

function install-system-requirements() {
    if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ]; }; then
        if [ ! -x "$(command -v curl)" ]; then
            if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ]; }; then
                apt-get update
                apt-get install curl -y
            fi
        fi
    else
        echo "Error: ${DISTRO} not supported."
        exit
    fi
}

install-system-requirements

function install-chrome-headless() {
    if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ]; }; then
        apt-get update
        apt-get upgrade -y
        apt-get dist-upgrade -y
        apt-get install task-xfce-desktop xscreensaver xfce4 desktop-base build-essential -y
        curl https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb -o /tmp/chrome-remote-desktop_current_amd64.deb
        dpkg --install /tmp/chrome-remote-desktop_current_amd64.deb
        rm -f /tmp/chrome-remote-desktop_current_amd64.deb
        echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" >>/etc/chrome-remote-desktop-session
        curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /tmp/google-chrome-stable_current_amd64.deb
        dpkg --install /tmp/google-chrome-stable_current_amd64.deb
        rm -f /tmp/google-chrome-stable_current_amd64.deb
        apt-get install --fix-broken -y
    fi
}

install-chrome-headless

function handle-services() {
    if pgrep systemd-journal; then
        systemctl stop lightdm.service
        systemctl disable lightdm.service
    else
        # fail2ban
        service lightdm.service stop
        service lightdm.service disable
    fi
}

handle-services
