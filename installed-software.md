# Software manually installed on Audacious Post-INSTALL.md

steam-installer
discord
zoom

zathura # lightweight document viewer
zathura-pdf-poppler # poppler backend for pdf files
lf # terminal file manager
imv # ightweight Wayland image viewer, integrates with lf

fonts-symbola
fonts-noto

cryptsetup # needed to unlock /dev/sda1 (LUKS backup drive)

wakeonlan
nfs-common # NFS client utilities for network shares
autofs # automounts NFS shares when accessed

golang-go # Go toolchain; used to build/run the Boot.dev learning client

borgbackup

powertop # interactive tool to diagnose and optimize power consumption
power-profiles-daemon # system service managing power modes 

usbutils # provides lsusb
jq # command-line JSON processor; used in idle-shutdown.sh
