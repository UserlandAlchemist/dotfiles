# root-backup-audacious

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

    sudo stow --target=/ root-backup-audacious
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
    - `borg-backup.service` uses `/usr/local/lib/borg/run-backup.sh` which
      sends WOL and waits for repository availability (60s timeout).
    - `borg-check.service` uses `/usr/local/lib/borg/wait-for-astute.sh` as
      an `ExecStartPre=` to wake Astute before running integrity checks.
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

- `borg-backup.service` runs `/usr/local/lib/borg/run-backup.sh` which performs:
  1. Wake-on-LAN to Astute
  2. `borg create` with progress and stats
  3. `borg prune` to apply retention rules (keep last 2 backups)
  4. `borg compact` to reclaim space

  The service runs as **root** under `systemd-inhibit --what=shutdown:sleep`
  to prevent system shutdown during backup.

- `borg-check.service` runs as user `alchemist` and performs quick repository
  integrity checks. Uses `EnvironmentFile=/home/alchemist/.config/borg/env`.

- `borg-check-deep.service` performs full deep verification monthly.

---

## Troubleshooting

### Timers show as "enabled" but don't run

**Symptom:** `systemctl list-timers` shows "-" for NEXT/LAST, or timers don't appear at all.

**Cause:** Timers were enabled but not started. The `--now` flag both enables and starts,
but if you only ran `systemctl enable`, the timer won't activate until next boot.

**Fix:**
```bash
sudo systemctl daemon-reload
sudo systemctl start borg-backup.timer borg-check.timer borg-check-deep.timer
systemctl list-timers | grep borg  # Verify timers are scheduled
```

### Permission denied on Borg cache or config

**Symptom:** `borg list` or manual backup commands fail with "Permission denied" on
`~/.config/borg/security/`.

**Cause:** `borg-backup.service` runs as root and may create root-owned security files
in the user's home directory.

**Fix:**
```bash
sudo chown -R alchemist:alchemist ~/.config/borg/security/
```

**Note:** The service uses a separate cache directory (`/var/cache/borg/audacious-backup/`)
to avoid conflicts with user commands. The service must run as root to use
`systemd-inhibit --what=shutdown:sleep` (user services cannot create system-wide
shutdown inhibitors).

### Verify backups are running

Check recent backup archives:
```bash
source ~/.config/borg/env
borg list "$BORG_REPO"
```

Check last backup time:
```bash
borg list "$BORG_REPO" --last 1
```

Check service status:
```bash
systemctl status borg-backup.service
journalctl -u borg-backup.timer -u borg-backup.service --since "1 week ago"
```

---

## Related packages

- `borg-user-audacious/` — per-user Borg environment and patterns
- `ssh-audacious/` — SSH configuration containing the backup key
- `docs/audacious/INSTALL.audacious.md` — installation reference