# root-power-audacious

System power and latency tuning.

Includes:

- udev rules to prevent autosuspend on critical USB devices
  (keyboard, mouse, webcam)
- hdparm / SATA power policies
- powertop.service (aggressive power savings)
- usb-nosuspend.service (undoes powertop's autosuspend on
  human I/O devices)

## Deploy

```bash
sudo ./root-power-audacious/install.sh
sudo systemctl enable --now powertop.service usb-nosuspend.service
sudo udevadm control --reload-rules
sudo udevadm trigger
```

## Notes

- Settings tuned for responsive desktop with selective power savings.
- The `usb-nosuspend.service` unit runs a helper script at
  `/usr/local/sbin/usb-nosuspend.sh` to ensure keyboards,
  mice, and webcams remain fully powered.
- The udev rules under `/etc/udev/rules.d/` are applied
  automatically after `udevadm trigger`, but may require
  unplug/replug for some devices.
- `powertop.service` can be disabled if you prefer less aggressive power management:

      sudo systemctl disable --now powertop.service

- Verify active rules with:

      sudo udevadm info --attribute-walk /sys/class/input/event0
