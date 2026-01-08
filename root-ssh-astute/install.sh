#!/bin/sh
# Install root-ssh-astute package

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

echo "Installing root-ssh-astute (sshd hardening)"

install_sshd_dropin 10-listenaddress.conf
install_config etc/systemd/system/ssh.service.d/wait-for-network.conf

echo "→ Validating sshd config"
sshd -t

echo "→ Restarting sshd"
systemctl restart ssh

install_success
