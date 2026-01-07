#!/bin/sh
# Install root-firewall-audacious package

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

echo "Installing root-firewall-audacious (nftables)"

install_config etc/nftables.conf

echo "→ Validating nftables config"
nft -c -f /etc/nftables.conf

echo "→ Enabling and restarting nftables"
systemctl enable --now nftables
systemctl restart nftables

install_success
