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
        if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v ufw)" ] || [ ! -x "$(command -v jq)" ]; }; then
            if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ]; }; then
                apt-get update
                apt-get install curl openssh-server openssh-client openssl jq haveged -y
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

function setup-firewall() {
    if [ -x "$(command -v sshd)" ]; then
        if [ -f "${SSHD_CONFIG}" ]; then
            rm -f "${SSHD_CONFIG}"
        fi
        if [ ! -f "${SSHD_CONFIG}" ]; then
            echo "Port 22
      PermitRootLogin no
      MaxAuthTries 3
      PasswordAuthentication no
      PermitEmptyPasswords no
      ChallengeResponseAuthentication no
      KerberosAuthentication no
      GSSAPIAuthentication no
      X11Forwarding no
      UsePAM yes
      X11Forwarding yes
      PrintMotd no
      PermitUserEnvironment no
      AllowAgentForwarding no
      AllowTcpForwarding no
      PermitTunnel no
      AcceptEnv LANG LC_*
      Subsystem sftp /usr/lib/openssh/sftp-server" >>"${SSHD_CONFIG}"
        fi
    fi
}

setup-firewall

function create-user() {
    SSHD_CONFIG="/etc/ssh/sshd_config"
    SERVER_HOST="$(curl -4 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
    INTERNAL_SERVER_HOST="$(ip route get 8.8.8.8 | grep src | sed 's/.*src \(.* \)/\1/g' | cut -f1 -d ' ')"
    if [ -z "${SERVER_HOST}" ]; then
        SERVER_HOST="$(ip route get 8.8.8.8 | grep src | sed 's/.*src \(.* \)/\1/g' | cut -f1 -d ' ')"
    fi
    if [ -f "/etc/chrome-remote-desktop-session" ]; then
        LINUX_USERNAME="$(openssl rand -hex 16)"
        LINUX_PASSWORD="$(openssl rand -hex 25)"
        SSH_LINUX_PASSWORD="$(openssl rand -hex 25)"
        useradd -m -s /bin/bash "${LINUX_USERNAME}"
        echo -e "${LINUX_PASSWORD}\n${LINUX_PASSWORD}" | passwd "${LINUX_USERNAME}"
        usermod -aG sudo "${LINUX_USERNAME}"
        USER_DIRECTORY="/home/${LINUX_USERNAME}"
        USER_SSH_FOLDER="${USER_DIRECTORY}/.ssh"
        mkdir -p "${USER_SSH_FOLDER}"
        chmod 700 "${USER_SSH_FOLDER}"
        PRIVATE_SSH_KEY="${USER_SSH_FOLDER}/id_ssh_ed25519"
        PUBLIC_SSH_KEY="${USER_SSH_FOLDER}/id_ssh_ed25519.pub"
        AUTHORIZED_KEY="${USER_SSH_FOLDER}/authorized_keys"
        ssh-keygen -o -a 2500 -t ed25519 -f "${PRIVATE_SSH_KEY}" -N "${SSH_LINUX_PASSWORD}" -C "${LINUX_USERNAME}@${SERVER_HOST}"
        cat "${PUBLIC_SSH_KEY}" >>"${AUTHORIZED_KEY}"
        chmod 600 "${AUTHORIZED_KEY}"
        chown -R "${LINUX_USERNAME}":"${LINUX_USERNAME}" "${USER_DIRECTORY}"
        echo "System External IP: ${SERVER_HOST}"
        echo "System Internal IP: ${INTERNAL_SERVER_HOST}"
        echo "Linux Username: ${LINUX_USERNAME}"
        echo "Linux Password: ${LINUX_PASSWORD}"
        echo "SSH Public Key: $(cat "${PUBLIC_SSH_KEY}")"
        echo "SSH Private Key: $(cat "${PRIVATE_SSH_KEY}")"
        echo "SSH Passphrase: ${SSH_LINUX_PASSWORD}"
    fi
}

create-user

function handle-services() {
    if pgrep systemd-journal; then
        # SSH
        systemctl restart ssh
        #
        systemctl stop lightdm
    else
        # SSH
        service ssh restart
        #
        service lightdm stop
    fi
}

handle-services
