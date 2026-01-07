#!/bin/sh
# Install root-cachyos-audacious package

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

echo "Installing root-cachyos-audacious (gaming/performance tweaks)"

# Install systemd configs as real files (no symlinks to /home)
install_config etc/systemd/user.conf.d/limits.conf
install_config etc/systemd/system.conf.d/00-timeout.conf
install_config etc/systemd/system.conf.d/limits.conf

# Install sysctl, tmpfiles, modprobe, and udev configs as real files
install_config etc/sysctl.d/99-gaming-desktop-settings.conf
install_config etc/tmpfiles.d/thp.conf
install_config etc/tmpfiles.d/coredump.conf
install_config etc/modprobe.d/20-audio-pm.conf
install_config etc/modprobe.d/blacklist.conf
install_config etc/udev/rules.d/20-audio-pm.rules.disabled
install_config etc/udev/rules.d/30-zram.rules
install_config etc/udev/rules.d/40-hpet-permissions.rules
install_config etc/udev/rules.d/50-sata.rules.disabled
install_config etc/udev/rules.d/60-ioschedulers.rules
install_config etc/udev/rules.d/69-hdparam.rules.disabled
install_config etc/udev/rules.d/99-cpu-dma-latency.rules

reload_systemd
install_success
