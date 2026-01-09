# theme-audacious

Workbench Dark theme for GTK3, fonts, icons, and wallpapers.

**Purpose:** Applies Amiga Workbench color palette over Arc-Dark GTK theme base.

## Architecture

Uses GTK3's override system instead of forking themes:

- **Base theme:** Arc-Dark (well-maintained, apt-managed)
- **Color override:** `~/.config/gtk-3.0/gtk.css` replaces Arc's blue-grays with Workbench pure grays
- **Settings:** `~/.config/gtk-3.0/settings.ini` points to Arc-Dark and enables dark mode preference

## Why This Approach

1. **Stability:** Arc-Dark is actively maintained and receives updates
2. **Git-tracked:** Override CSS is version-controlled in dotfiles
3. **Non-destructive:** Doesn't modify system theme files
4. **Portable:** Stow-managed, easy to deploy/remove

## Color Replacements

Arc-Dark's blue-gray palette → Workbench pure grays:

| Element | Arc-Dark | Workbench Override |
|---------|----------|-------------------|
| Panel background | `#383c4a` (blue-gray) | `#242424` (pure gray) |
| Darker areas | `#2f343f` | `#202020` |
| Borders | `#5294e2` (blue) | `#303030` (gray) |
| Selected items | `#5294e2` | `#5078FF` (Workbench blue) |
| Text | Similar | `#E6E6E6` |

## Files

- **settings.ini** – Points GTK to Arc-Dark, enables dark mode preference
- **gtk.css** – CSS overrides for Workbench color palette

## Dependencies

- `arc-theme` package (provides Arc-Dark)
- `lxappearance` (optional, for GUI theme selection)

Install:

```bash
sudo apt install arc-theme lxappearance
```

## Deployment

```bash
cd ~/dotfiles
stow gtk-audacious
```

GTK apps will pick up the settings immediately (may need to restart running apps).

## Testing

- **File picker:** `gtk3-demo` → File chooser
- **Theme preview:** `lxappearance`
- **System dialogs:** Open any GTK app (Firefox ESR, GNOME apps, etc.)

Expected result: GTK apps use Arc-Dark's design with Workbench's gray/blue color palette instead of Arc's blue-grays.

## Workbench Aesthetic Consistency

Matches color palette from:

- waybar-audacious (title bar with beveled borders)
- wofi-audacious (app launcher)
- mako-audacious (notifications)
- sway-audacious (window borders)

All use standardized Workbench palette:

- Panel: `#242424`
- Background: `#202020`
- Border: `#303030`
- Text: `#E6E6E6`
- Shadow: `#606060`
- Blue: `#5078FF`
- Orange: `#FFA040`
- Teal: `#40C8FF`
