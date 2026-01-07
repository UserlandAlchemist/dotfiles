#!/bin/sh
# Install root-proaudio-audacious package

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

echo "Installing root-proaudio-audacious (real-time audio limits)"

install_config etc/security/limits.d/20-audio.conf

install_success
