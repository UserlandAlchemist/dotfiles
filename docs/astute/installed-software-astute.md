# Installed Software (Structured List)

Curated inventory of manually installed packages on Astute. Sections reflect installation origin, not function. This list is derived from `apt-mark showmanual` and focuses on non-bootstrap additions.

Last drift check: 2026-01-08

---

## Base System (via install-astute.md §1-7)

### Firmware & microcode
- intel-microcode — CPU microcode updates
- firmware-amd-graphics — AMD GPU firmware

### Crypto & storage
- cryptsetup — LUKS tooling for the admin USB (optional)

### ZFS stack
- zfs-dkms — ZFS kernel module build
- zfsutils-linux — ZFS userland tools
- zfs-zed — ZFS event daemon

### NAS & backup
- nfs-kernel-server — NFS exports for /srv/nas
- borgbackup — encrypted backup server

### Power & monitoring
- powertop — power tuning
- lm-sensors — sensor probes
- smartmontools — SMART monitoring

### Utilities
- ethtool — NIC tuning
- git — version control
- stow — dotfile deployment
- htop — process monitor
- vim — editor
- nano — fallback editor
- tree — directory inspection
- jq — JSON processor
- rsync — file sync utility
- curl — HTTP download utility
- nftables — host firewall tooling
- usbutils — USB inspection tools
- iproute2 — modern networking tools
- iputils-ping — ping utility
- systemd-resolved — systemd DNS resolver

### System management
- unattended-upgrades — automated security updates
- apt-cacher-ng — LAN apt cache

### Tasksel meta packages
- task-ssh-server — SSH server task

---

## Media Services (optional, via install-astute.md §13)

- jellyfin — media server
- jellyfin-ffmpeg7 — Jellyfin ffmpeg build
- mpd — music playback daemon
