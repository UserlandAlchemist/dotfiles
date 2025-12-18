# backup-systemd-audacious

Systemd timers and services for unattended BorgBackup on host audacious.

Installs:
- `borg-backup.service` / `.timer`
- `borg-check.service` / `.timer`
- `borg-check-deep.service` / `.timer`

These units perform automated backups and regular integrity checks
using BorgBackup. All Borg commands are executed in non-interactive
mode using environment variables defined in the user configuration.

---

## Deploy

Run as root:

    sudo stow --target=/ backup-systemd-audacious
    sudo systemctl daemon-reload
    sudo systemctl enable --now \
        borg-backup.timer \
        borg-check.timer \
        borg-check-deep.timer

After enabling, verify that timers are active:

    systemctl list-timers | grep borg

---

## Prerequisites

Before enabling the timers, ensure all of the following are in place.

1. Borg and configuration

    - The `borgbackup` package is installed on this host.
    - The per-user Borg configuration from `borg-user-audacious/` has
      been stowed for the backup user (`alchemist`).
    - `~/.config/borg/env` exists and defines `BORG_REPO`, `BORG_PASSCOMMAND`,
      and `BORG_RSH`.
    - `~/.config/borg/passphrase` exists and contains the repository passphrase.
    - `~/.config/borg/patterns` exists and defines include/exclude rules.

2. SSH access to the backup target

    - The Borg repository is remote, for example:
          ssh://borg@astute/srv/backups/audacious-borg
    - The environment variable `BORG_RSH` points to a specific key, such as:
          ssh -i /home/alchemist/.ssh/audacious-backup -T
    - The corresponding public key is present in:
          ~borg/.ssh/authorized_keys
    - The remote path exists and is writable by the Borg user on `astute`.

3. Network reachability

    - The target host (`astute`) must be online or reachable via Wake-on-LAN.
    - Each unit uses the helper script:
          /usr/local/lib/borg/wait-for-astute.sh
      to send a magic packet and wait briefly before invoking Borg.
    - If the host is unreachable, Borg will exit with an error and
      the timer will retry at the next scheduled interval.

---

## Sanity checks

Run as the backup user (`alchemist`) to confirm non-interactive access:

    ~/.config/borg/env.sh borg list

If repository access succeeds, systemd timers will run without prompting
for passwords or manual input.

---

## Details

- `borg-backup.service` performs the main backup operation and runs
  `borg prune` as `ExecStartPost=` to apply retention rules.
- `borg-check.service` performs a quick weekly repository check.
- `borg-check-deep.service` performs a full integrity check monthly.

All units use the shared environment file:

    EnvironmentFile=%h/.config/borg/env

and assume the repository and SSH configuration are defined there.

---

## Related packages

- `borg-user-audacious/` — per-user Borg environment and patterns
- `ssh-audacious/` — SSH configuration containing the backup key
- `docs/audacious/INSTALL.audacious.md` — installation reference