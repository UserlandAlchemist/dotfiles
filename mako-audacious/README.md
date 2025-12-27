# mako-audacious

Notification daemon configuration using Workbench aesthetic.

---

## Monitor Configuration

Audacious has a dual-monitor setup:

- **HDMI-A-1**: LG ULTRAWIDE (secondary monitor, right)
- **DP-1**: MSI MAG274UPF (main monitor, left)

Notifications are configured to appear on the secondary monitor (HDMI-A-1) via the `output=HDMI-A-1` setting in `config`.

---

## Visual Design

- **Font**: Topaz Plus NF Mono 14
- **Colors**: Workbench-inspired palette
  - Background: `#242424EE` (dark gray, semi-transparent)
  - Text: `#E6E6E6` (light gray)
  - Border: `#5078FF` (blue, matches Waybar/Sway theme)
  - Progress: `#40C8FF` (cyan)
- **Position**: Top-right corner
- **Format**: Bold app name, then body text

---

## Testing

Reload configuration:
```sh
makoctl reload
```

Test notification:
```sh
notify-send -a "Test" "" "Test message"
```

Should appear on LG ULTRAWIDE (left monitor).
