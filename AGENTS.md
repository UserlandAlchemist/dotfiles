# Repository Guidelines

## Project Structure & Module Organization
GNU Stow dotfiles for multiple hosts (audacious, astute, artful, steamdeck).
- User packages: `<tool>-<hostname>/` (e.g., `bash-audacious/`, `sway-audacious/`) → `$HOME`.
- System packages: `root-<concern>-<hostname>/` → `/`.
- Shared profile: `profile-common/`.
- Docs: `docs/<hostname>/` with `INSTALL`, `RECOVERY`, `RESTORE`.

## Build, Test, and Development Commands
- `stow profile-common bash-audacious bin-audacious`: deploy user configs.
- `sudo stow --target=/ root-power-audacious`: deploy system configs.
- `stow --restow bash-audacious`: restow after edits.
- `sudo systemctl daemon-reload`: after unit changes.
- `journalctl -u <service> -n 50`: service logs.

## Coding Style & Naming Conventions
- Plain bash + systemd; no wrappers or daemons.
- Host-specific config; avoid shared files that block single-host recovery.
- Package naming as above; consistent `root-<concern>-<host>` pattern.
- Never commit secrets (SSH keys, borg passphrases, tokens).

## Testing Guidelines
- Units: `sudo systemctl daemon-reload && sudo systemctl restart <service>`.
- Timers: `systemctl list-timers`.
- Idle shutdown: `~/bin/idle-shutdown.sh` + `journalctl -t idle-shutdown -f`.
- NAS wake: `nas-open` / `nas-close`, verify mounts and inhibitors.
- Borg: `sudo systemctl start borg-backup.service` + logs.

## Commit & Pull Request Guidelines
- Commit messages: imperative, why-focused, include host context.
- Co-authored-by is OK for AI assistance.

## Claude ↔ Codex Workflow
- Audience: LLMs. Keep outputs terse and repo-specific.
- Claude: operator + reviewer (SSH, system state, docs, sign-off).
- Codex: implementer (edits, scripts, units, quick analysis).
- After Codex work, include:
```
Handoff (Codex → Claude)
Goal:
Scope/files:
Assumptions:
Commands run + key outputs:
Diff summary:
Risks/unknowns:
Tests run/needed:
Docs updated/needed:
```

## Security & Configuration Tips
- Sudoers via `install.sh` + `install -o root -g root -m 0440` + `visudo -c`.
- Update recovery docs when rebuild/restore steps change.
