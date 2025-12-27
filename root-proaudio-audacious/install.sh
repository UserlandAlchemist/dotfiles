#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

echo "Installing root-proaudio-audacious (real-time audio limits)"

install -o root -g root -m 0644 \
  "$PKG_DIR/etc/security/limits.d/20-audio.conf" \
  /etc/security/limits.d/20-audio.conf

echo "✓ root-proaudio-audacious installed successfully"
