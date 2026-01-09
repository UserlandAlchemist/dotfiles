# root-borg-audacious

Systemd timers and services for unattended BorgBackup on Audacious.

Manages two independent backup streams:
- **Local backups** → Astute NAS (daily, 7-day retention)
- **Offsite backups** → BorgBase (daily, append-only for ransomware protection)

---

## Deploy

```bash
sudo ./root-borg-audacious/install.sh
```

Enable timers:

```bash
sudo systemctl enable --now \
  borg-backup.timer \
  borg-check.timer \
  borg-check-deep.timer \
  borg-offsite-audacious.timer \
  borg-offsite-check.timer
```

Verify timers are active:

```bash
systemctl list-timers | grep borg
```

---

## Local Backups (Astute NAS)

### Units

- `borg-backup.service` / `.timer` — daily backups to Astute
- `borg-check.service` / `.timer` — weekly integrity checks
- `borg-check-deep.service` / `.timer` — monthly deep verification

### Prerequisites

1. **Borg and configuration**
   - `borgbackup` package installed
   - User Borg config from `borg-user-audacious/` stowed for `alchemist`
   - `~/.config/borg/env` defines `BORG_REPO`, `BORG_PASSCOMMAND`, `BORG_RSH`
   - `~/.config/borg/passphrase` exists with repository passphrase
   - `~/.config/borg/patterns` defines include/exclude rules

2. **SSH access to Astute**
   - Borg repository: `ssh://borg@astute/srv/backups/audacious-borg`
   - `BORG_RSH` points to specific key: `ssh -i /home/alchemist/.ssh/audacious-backup -T`
   - Public key in `~borg/.ssh/authorized_keys` on Astute
   - Remote path exists and writable by borg user

3. **Network reachability**
   - Astute must be online or reachable via Wake-on-LAN
   - Scripts handle WOL and wait for repository (60s timeout)
   - If unreachable, timer retries at next interval

### Details

- `borg-backup.service` runs `/usr/local/lib/borg/run-backup.sh`:
  1. Wake-on-LAN to Astute
  2. `borg create` with progress and stats
  3. `borg prune` (keep 7 daily backups)
  4. `borg compact` to reclaim space

  Runs as **root** under `systemd-inhibit --what=shutdown:sleep` to prevent shutdown during backup.

- `borg-check.service` runs as user `alchemist` with quick repository integrity checks
- `borg-check-deep.service` performs full deep verification monthly

### Troubleshooting

**Timers show "enabled" but don't run:**
```bash
sudo systemctl daemon-reload
sudo systemctl start borg-backup.timer borg-check.timer borg-check-deep.timer
systemctl list-timers | grep borg
```

**Permission denied on Borg cache/config:**

`borg-backup.service` runs as root and may create root-owned security files:
```bash
sudo chown -R alchemist:alchemist ~/.config/borg/security/
```

Note: Service uses separate cache (`/var/cache/borg/audacious-backup/`) to avoid conflicts.

**Verify backups are running:**
```bash
source ~/.config/borg/env
borg list "$BORG_REPO"
borg list "$BORG_REPO" --last 1
systemctl status borg-backup.service
journalctl -u borg-backup.timer -u borg-backup.service --since "1 week ago"
```

---

## Offsite Backups (BorgBase)

### Units

- `borg-offsite-audacious.timer` — daily at 14:00 (Persistent + WakeSystem)
- `borg-offsite-check.timer` — monthly (Persistent + WakeSystem)

### Prerequisites

1. BorgBackup installed (borg 1.x)
2. BorgBase SSH key installed:
   - Private: `/root/.ssh/borgbase-offsite-audacious`
   - Public uploaded to BorgBase
3. Passphrase file (root-only):
   - `/root/.config/borg-offsite/audacious-home.passphrase`
4. BorgBase repo created with append-only access
5. Audacious Borg patterns stowed for `alchemist`:
   - `/home/alchemist/.config/borg/patterns`

### Details

Backs up Audacious home data → `audacious-home` repository.

**Critical:** Append-only SSH key assignment required for ransomware protection. See `docs/offsite-backup.md` for verification, repo initialization, and restore steps.

**Important:** `audacious-home` uses append-only access; do not prune or compact from Audacious.

### Troubleshooting

Check logs:
```bash
journalctl -u borg-offsite-*.service
```

---

## Sanity Checks

Run as backup user (`alchemist`) to confirm non-interactive access:

```bash
~/.config/borg/env.sh borg list
```

If repository access succeeds, systemd timers will run without prompting.

---

## Related Packages

- `borg-user-audacious/` — per-user Borg environment and patterns
- `ssh-audacious/` — SSH configuration containing backup keys
- `docs/audacious/install-audacious.md` — installation reference
- `docs/offsite-backup.md` — BorgBase setup and operations
