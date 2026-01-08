# Drift Check Procedure

Verify system state matches documentation.

## Prerequisite

`check-drift.sh` is provided by `bin-common/` and must be stowed into `~/.local/bin`.

## Run check

```sh
check-drift.sh
```

Script compares `installed-software.audacious.md` against `apt-mark showmanual`.

## Expected output (no drift)

```
✓ No drift detected
  Documented: 85 packages
  Installed:  85 packages
```

## Drift detected

Script reports:
- **Documented but NOT installed** — packages removed from system
- **Installed but NOT documented** — new packages added

## Resolve drift

**Intentional changes:** Update `installed-software.audacious.md` to reflect system reality.

**Accidental drift:** Either:
- Install missing packages: `sudo apt install <package>`
- Remove undocumented packages: `sudo apt remove --purge <package>`

## Update timestamp

After resolving drift:

```sh
editor ~/dotfiles/docs/audacious/installed-software.audacious.md
```

Update "Last drift check" date, commit changes.

## Frequency

Run monthly or:
- Before system backup
- After installing new software
- Before creating system documentation
