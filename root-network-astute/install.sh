#!/bin/sh
# Install root-network-astute package

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

echo "Installing root-network-astute (systemd-networkd)"

install_config etc/systemd/network/10-wired.link
install_config etc/systemd/network/20-wired.network
install_config etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf

install_success
