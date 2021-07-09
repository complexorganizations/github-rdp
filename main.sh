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
    DISTRO_VERSION=${VERSION_ID}
  fi
}

# Check Operating System
dist-check

