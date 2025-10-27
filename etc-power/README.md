# etc-power

System power + latency tuning.

This stow package installs:
- udev rules to prevent autosuspend on critical USB devices (keyboard, mouse, webcam)
- hdparm / SATA power policies
- powertop.service (aggressive power savings)
- usb-nosuspend.service (undo powertop's autosuspend on human I/O devices)

## Deploy

Run as root:

```sh
sudo stow --target=/ etc-power
sudo systemctl daemon-reload
sudo systemctl enable --now powertop.service usb-nosuspend.service
sudo udevadm control --reload-rules
sudo udevadm trigger
