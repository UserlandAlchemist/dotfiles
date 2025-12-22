# Repository Guidelines

## Project Structure & Module Organization
This is a GNU Stow-managed dotfiles repository for multiple hosts (audacious, astute, artful, steamdeck). Packages are grouped by host and concern:
- User packages: `<tool>-<hostname>/` (e.g., `bash-audacious/`, `sway-audacious/`) stow to `$HOME`.
- System packages: `root-<concern>-<hostname>/` or `root-<hostname>-<concern>/` (inconsistent, being standardized) stow to `/`.
- Shared profile: `profile-common/`.
- Docs: `docs/<hostname>/` with `INSTALL`, `RECOVERY`, `RESTORE` guides.

## Build, Test, and Development Commands
- `stow profile-common bash-audacious bin-audacious`: deploy user configs.
- `sudo stow --target=/ root-power-audacious`: deploy system configs.
- `stow --restow bash-audacious`: restow after edits.
- `sudo systemctl daemon-reload`: reload systemd after unit changes.
- `journalctl -u <service> -n 50`: inspect service logs.

## Coding Style & Naming Conventions
- Prefer plain, explicit bash and systemd units; no wrappers or daemons.
- Keep configs host-specific; avoid shared files that break single-host recovery.
- Name packages as described above; note current `root-*` naming drift.
- Avoid committing secrets (SSH keys, borg passphrases, tokens).

## Testing Guidelines
- Systemd units: `sudo systemctl daemon-reload && sudo systemctl restart <service>`.
- Timers: `systemctl list-timers` after changes.
- Idle shutdown: `~/bin/idle-shutdown.sh` and `journalctl -t idle-shutdown -f`.
- NAS wake: run `nas-open` and `nas-close`, verify mounts and inhibitors.
- Borg: `sudo systemctl start borg-backup.service` and check logs.

## Commit & Pull Request Guidelines
- Commit messages use imperative mood, focus on “why,” and often include host context.
- Include a Co-authored-by footer for AI assistance if desired.

## Security & Configuration Tips
- Sudoers files must use `install.sh` with `install -o root -g root -m 0440` and `visudo -c`.
- Recovery docs should be updated when changes affect rebuild or restore steps.
