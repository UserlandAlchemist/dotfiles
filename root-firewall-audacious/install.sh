#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

install_nftables() {
  SOURCE="$PKG_DIR/etc/nftables.conf"
  TARGET="/etc/nftables.conf"

  install -m 0644 "$SOURCE" "$TARGET"
}

echo "Installing root-firewall-audacious (nftables)"

install_nftables

echo "→ Validating nftables config"
nft -c -f /etc/nftables.conf

echo "→ Enabling and restarting nftables"
systemctl enable --now nftables
systemctl restart nftables

echo "✓ root-firewall-audacious installed successfully"
