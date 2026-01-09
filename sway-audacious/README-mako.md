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

Workbench-inspired dark mode aesthetic with color-coded urgency levels.

- **Font**: Topaz Plus NF Mono 16
- **Size**: 600px wide, up to 300px tall with text wrapping
- **Position**: Top-right corner of secondary monitor
- **Padding**: Generous 16px padding for retro chunky look
- **Border**: 3px solid border (thickness matches Workbench window chrome)

**Colors by urgency:**
- **Low**: Gray title and border (`#808080`), 8s timeout
- **Normal**: Blue title and border (`#5078FF`), 10s timeout
- **High**: Orange title and border (`#FFA040`), stays until dismissed

**Base colors:**
- Background: `#2A2A2AEE` (dark gray, semi-transparent)
- Text: `#E6E6E6` (light gray)
- Progress: `#40C8FF` (cyan)

**Format**: Bold colored title, blank line, then body text

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
