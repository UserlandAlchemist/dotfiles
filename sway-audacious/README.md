# sway-audacious

Sway window manager and Wayland compositor ecosystem for Audacious.

This consolidated package contains all Wayland desktop components:

- **Sway** — Tiling window manager
- **Waybar** — Status bar
- **Foot** — Terminal emulator
- **Wofi** — Application launcher
- **Mako** — Notification daemon

All components share the Workbench-inspired dark aesthetic with Topaz Plus fonts.

---

## Deploy

```bash
cd ~/dotfiles
stow sway-audacious
```

Launch Sway from TTY1 (configured in `bash-audacious/.bash_profile.d/20-sway.sh`):

```bash
# Login to TTY1, Sway starts automatically
```

---

## Components

### Sway (Window Manager)

**Config:** `.config/sway/config`

Tiling window manager with:

- Mod key: Super (Windows key)
- Workspaces 1-10
- Dual monitor layout (DP-1 primary left, HDMI-A-1 secondary right)
- Workbench color scheme
- Auto-launched: waybar, mako

### Waybar (Status Bar)

**Config:** `.config/waybar/config.jsonc`, `.config/waybar/style.css`

Status bar showing:

- Workspaces
- Window title
- System tray
- Clock
- Workbench-styled with Topaz Plus font

### Foot (Terminal)

**Config:** `.config/foot/foot.ini`

Fast Wayland-native terminal with:

- Topaz Plus NF Mono font
- Workbench color palette
- Configurable key bindings

### Wofi (Application Launcher)

**Config:** `.config/wofi/config`, `.config/wofi/style.css`

Wayland application launcher:

- Dmenu-style interface
- Workbench aesthetic
- Keyboard-driven workflow

### Mako (Notifications)

**Config:** `.config/mako/config`

Notification daemon with Workbench aesthetic and color-coded urgency levels.

#### Monitor Configuration

Audacious has a dual-monitor setup:

- **HDMI-A-1**: LG ULTRAWIDE (secondary monitor, right)
- **DP-1**: MSI MAG274UPF (main monitor, left)

Notifications appear on the secondary monitor (HDMI-A-1) via `output=HDMI-A-1`.

#### Visual Design

- **Font**: Topaz Plus NF Mono 16
- **Size**: 600px wide, up to 300px tall with text wrapping
- **Position**: Top-right corner of secondary monitor
- **Padding**: 16px padding for retro chunky look
- **Border**: 3px solid border (matches Workbench window chrome)

**Colors by urgency:**

- **Low**: Gray title/border (`#808080`), 8s timeout
- **Normal**: Blue title/border (`#5078FF`), 10s timeout
- **High**: Orange title/border (`#FFA040`), stays until dismissed

**Base colors:**

- Background: `#2A2A2AEE` (dark gray, semi-transparent)
- Text: `#E6E6E6` (light gray)
- Progress: `#40C8FF` (cyan)

#### Testing Mako

Reload configuration:

```sh
makoctl reload
```

Test notification:

```sh
notify-send -a "Test" "Title" "Test message"
```

Should appear on LG ULTRAWIDE (right monitor).

---

## Notes

- All components use Topaz Plus fonts (deployed via `theme-audacious`)
- Workbench color palette consistent across all components
- GTK theme settings from `theme-audacious` apply to GTK apps in Sway
- Icon theme (AmigaCursors) from `theme-audacious` applies system-wide
