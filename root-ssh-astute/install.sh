#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

install_sshd_dropin() {
  CONF="$1"
  SOURCE="$PKG_DIR/etc/ssh/sshd_config.d/$CONF"
  TARGET="/etc/ssh/sshd_config.d/$CONF"

  mkdir -p /etc/ssh/sshd_config.d
  install -m 0644 "$SOURCE" "$TARGET"
}

echo "Installing root-ssh-astute (sshd hardening)"

install_sshd_dropin 10-listenaddress.conf

echo "→ Validating sshd config"
sshd -t

echo "→ Restarting sshd"
systemctl restart ssh

echo "✓ root-ssh-astute installed successfully"
