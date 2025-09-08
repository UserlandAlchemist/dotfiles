# dotfiles

My personal dotfiles for a minimal, Amiga-themed Sway desktop on Debian.

## Includes
- **Sway** – window manager config (Amiga look & feel)
- **Waybar** – status bar config + CSS styling
- **Foot** – terminal config
- **Mako** – notification daemon config
- **Emacs** – init + custom theme (`amiga-dark-theme.el`)
- **Fonts** – Amiga Topaz fonts + NerdFont variant
- **Cursors** – AmigaCursors theme
- **Wallpapers** – Workbench-style wallpapers
- **Scripts** – e.g. `select-audio-sink.sh` (PipeWire)

## Requirements
Tested on **Debian 13 (Trixie)** with:
- sway, swaybg, swayidle, swaylock  
- waybar  
- foot  
- mako-notifier  
- pipewire-audio, wireplumber, pavucontrol, alsa-utils  
- fonts-jetbrains-mono  
- network-manager, mate-polkit  
- xwayland  

## Usage
Clone and deploy with GNU Stow:
```bash
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow -v fonts icons wallpapers foot mako sway waybar emacs bin