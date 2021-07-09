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
    if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ] || [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ] || [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ] || [ "${DISTRO}" == "alpine" ] || [ "${DISTRO}" == "freebsd" ]; }; then
        if [ ! -x "$(command -v curl)" ]; then
            if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ]; }; then
                apt-get update
                apt-get install curl
            elif { [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
                yum update -y
                yum install curl
            elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ]; }; then
                pacman -Syu
                pacman -Syu --noconfirm curl
            elif [ "${DISTRO}" == "alpine" ]; then
                apk update
                apk add curl
            elif [ "${DISTRO}" == "freebsd" ]; then
                pkg update
                pkg install curl
            fi
        fi
    else
        echo "Error: ${DISTRO} not supported."
        exit
    fi
}

install-system-requirements

function install-chrome-headless() {
    if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ] || [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ] || [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ] || [ "${DISTRO}" == "alpine" ] || [ "${DISTRO}" == "freebsd" ]; }; then
        apt-get update
        apt-get upgrade -y
        apt-get dist-upgrade -y
        apt-get install task-xfce-desktop xscreensaver xfce4 desktop-base build-essential -y
        curl https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb -o /tmp/chrome-remote-desktop_current_amd64.deb
        dpkg --install chrome-remote-desktop_current_amd64.deb
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
    systemctl disable lightdm.service
    # UFW
    if [ -x "$(command -v ufw)" ]; then
        ufw --force enable
        ufw default allow incoming
        ufw default allow outgoing
    fi
    if pgrep systemd-journal; then
        # Fail2ban
        systemctl enable fail2ban
        systemctl restart fail2ban
        # Ufw
        systemctl enable ufw
        systemctl restart ufw
    else
        # fail2ban
        service fail2ban enable
        service fail2ban restart
        # ufw
        service ufw enable
        service ufw restart
    fi
}

handle-services
