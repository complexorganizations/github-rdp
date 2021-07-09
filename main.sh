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
        if { [ ! -x "$(command -v sed)" ] || [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v ufw)" ] || [ ! -x "$(command -v fail2ban)" ] || [ ! -x "$(command -v ssh)" ] || [ ! -x "$(command -v openssl)" ] || [ ! -x "$(command -v lsof)" ] || [ ! -x "$(command -v gpg)" ]; }; then
            if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ]; }; then
                apt-get update
                apt-get install haveged fail2ban ufw lsof openssh-server openssh-client openssl jq curl sed lsof gpg -y
            elif { [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
                yum update -y
                yum install haveged fail2ban ufw lsof openssh-server openssh-client openssl jq curl sed lsof gpg -y
            elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ]; }; then
                pacman -Syu
                pacman -Syu --noconfirm haveged fail2ban ufw lsof openssh-server openssh-client openssl jq curl sed lsof gpg
            elif [ "${DISTRO}" == "alpine" ]; then
                apk update
                apk add haveged fail2ban ufw lsof openssh-server openssh-client openssl jq curl sed lsof gpg
            elif [ "${DISTRO}" == "freebsd" ]; then
                pkg update
                pkg install haveged fail2ban ufw lsof openssh-server openssh-client openssl jq curl sed lsof gpg
            fi
        fi
    else
        echo "Error: ${DISTRO} not supported."
        exit
    fi
}

install-system-requirements

function install-chrome-headless() {
    apt-get install task-xfce-desktop xscreensaver xfce4 desktop-base
    wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
    dpkg --install chrome-remote-desktop_current_amd64.deb
    echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" >>/etc/chrome-remote-desktop-session
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    dpkg --install google-chrome-stable_current_amd64.deb
    apt-get install --assume-yes --fix-broken
}

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
