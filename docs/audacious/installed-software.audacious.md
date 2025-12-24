# Installed Software (Structured List)

Machine-readable inventory of manually installed software. Sections reflect installation origin, not function. Enables auditable, reproducible system state.

Last drift check: 2025-12-22

---

## Base System (via INSTALL.audacious.md §1-13)

### Boot & filesystem
- cryptsetup — LUKS encryption for ZFS unlock
- zfs-initramfs — ZFS support during early boot
- linux-headers-amd64 — module build headers
- systemd-boot — EFI bootloader for UKI
- systemd-ukify — UKI generation tooling
- systemd-zram-generator — swap-on-zram backend
- intel-microcode — CPU microcode patches
- plymouth — graphical boot splash
- plymouth-themes — boot theme package

### Network & firmware
- openssh-client — SSH connectivity
- iproute2 — modern networking tools
- iputils-ping — ping utility
- firmware-amd-graphics — AMD GPU firmware
- firmware-realtek — NIC firmware

### Build tools (baseline)
- build-essential — compiler and build tools metapackage

### System utilities
- sudo — privilege escalation
- apt-listchanges — package changelog viewer
- usb.ids — USB device database
- usbutils — USB inspection tools (lsusb)

---

## Desktop Infrastructure (via INSTALL.audacious.md §14)

### Compositor & session
- sway — Wayland compositor
- swaybg — wallpaper management
- swayidle — power/idle controller
- swaylock — screen lock
- waybar — status bar
- wofi — application launcher
- mako-notifier — notification daemon
- xwayland — X11 compatibility
- mate-polkit — authentication agent

### Desktop utilities
- grim — screenshot tool
- slurp — region selection tool
- wl-clipboard — clipboard manager
- xdg-desktop-portal — desktop portal services
- xdg-desktop-portal-wlr — Wayland portal implementation

### Audio subsystem
- pipewire-audio — audio engine
- pipewire-jack — JACK compatibility layer
- wireplumber — policy/session manager
- pavucontrol — graphical mixer
- pulseaudio-utils — pactl utility
- playerctl — MPRIS media controller (critical for idle-shutdown)

### Development & dotfiles
- git — version control
- stow — dotfile deployment
- wget — HTTP download utility
- rsync — file/directory synchronization
- tree — directory visualizer
- jq — JSON processor
- npm — Node package manager (Codex dependency)
- emacs — text editor (dotfiles dependency)
- lf — terminal file manager
- nano — minimal fallback editor

### Storage & backup
- borgbackup — encrypted backups
- nfs-common — NFS client utilities
- wakeonlan — WOL magic packet sender
- hdparm — drive tuning

### Power management
- power-profiles-daemon — power profile control
- powertop — power optimization diagnostics

### Fonts
- fonts-jetbrains-mono — primary UI font
- fonts-dejavu — general fallback set
- fonts-noto — multilingual family
- fonts-symbola — Unicode symbol/emoji fallback

### Themes
- desktop-base — Debian branding defaults

### System utilities
- profile-sync-daemon — reduces browser write amplification
- nftables — firewall subsystem
- plocate — file indexer
- ncdu — interactive disk-usage inspector
- virt-viewer — SPICE/VNC viewer for libvirt VMs

---

## Integral 1.0 Audio Workstation

**See:** `~/personal/audio-workstation-notes.md` for complete documentation of the Integral audio workstation stack.

### Core packages (summary)
- ardour — DAW/recording software
- surge-xt — polyphonic synthesizer
- dragonfly-reverb-lv2 — reverb effect suite
- x42-plugins — LV2 effect plugin collection
- fluid-soundfont-gm — General MIDI soundfont
- faust — DSP development language
- golang-go — Go compiler (for Faust tooling + boot.dev CLI)

### Supporting libraries
- libmxml1 — XML parsing (audio plugin dependency)
- lilv-utils — LV2 plugin tools

---

## User Applications (post-installation)

### Web & communication
- firefox-esr — primary web browser
- discord — VoIP and community client
- zoom — video conferencing client

### Gaming
- heroic (local .deb) — Epic/GOG/Prime Gaming launcher
- steam-installer — Steam client (non-free)
- lutris — multi-platform game launcher
- prismlauncher — Minecraft launcher (open-source)
- openjdk-21-jdk — Java runtime for Minecraft

### Media
- vlc — media player
- jellyfin-media-player — Jellyfin client
- imv — Wayland image viewer
- gimp — image editor
- ncmpcpp — TUI music player client
- picard — music tagging software
- kid3-cli — music tagging CLI utility
- imagemagick — image manipulation CLI tools

### Documents
- zathura — PDF/document viewer
- zathura-pdf-poppler — rendering backend
- poppler-utils — PDF extraction toolkit
- tesseract-ocr — OCR engine

### Utilities
- transmission — torrent client
