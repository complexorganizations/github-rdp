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
                apt-get install curl haveged -y
            fi
        fi
    else
        echo "Error: ${DISTRO} not supported."
        exit
    fi
}

install-system-requirements

function install-chrome-headless() {
    chrome_remote_desktop_url="https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb"
    chrome_remote_desktop_local_path="/tmp/chrome-remote-desktop_current_amd64.deb"
    chrome_browser_url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    chrome_browser_local_path="/tmp/google-chrome-stable_current_amd64.deb"
    if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ]; }; then
        apt-get update
        apt-get install xfce4 -y
        apt-get install desktop-base -y
        apt-get install task-xfce-desktop -y
        apt-get install xscreensaver -y
        echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" >>/etc/chrome-remote-desktop-session
        curl ${chrome_remote_desktop_url} -o ${chrome_remote_desktop_local_path}
        dpkg --install ${chrome_remote_desktop_local_path}
        rm -f ${chrome_remote_desktop_local_path}
        curl ${chrome_browser_url} -o ${chrome_browser_local_path}
        dpkg --install ${chrome_browser_local_path}
        rm -f ${chrome_browser_local_path}
        apt-get install -f -y
    fi
}

install-chrome-headless

function handle-services() {
    if pgrep systemd-journal; then
        systemctl stop lightdm
    else
        service lightdm stop
    fi
}

handle-services
