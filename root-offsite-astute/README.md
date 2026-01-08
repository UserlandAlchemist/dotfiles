# root-offsite-astute

Off-site BorgBackup push from Astute to BorgBase.

Backs up:
- `/srv/backups/audacious-borg` → `audacious-home` (append-only)
- `/srv/nas/lucii` and `/srv/nas/bitwarden-exports` → `astute-critical` (append-only)

**Critical:** Append-only SSH key assignment is required for ransomware protection. See `docs/offsite-backup.md` for verification, repo initialization, and restore steps.

---

## Prerequisites

1. BorgBackup installed (borg 1.x).
2. BorgBase SSH key installed on Astute:
   - Private key: `/root/.ssh/borgbase_offsite`
   - Public key uploaded to BorgBase.
3. Passphrase files created (root-only):
   - `/root/.config/borg-offsite/audacious-home.passphrase`
   - `/root/.config/borg-offsite/astute-critical.passphrase`
4. BorgBase repos created:
   - audacious-home (normal)
   - astute-critical (append-only)

---

## Deploy

Install systemd units as real files:

```bash
sudo /home/alchemist/dotfiles/root-offsite-astute/install.sh
```

Enable timers:

```bash
sudo systemctl enable --now \
  borg-offsite-audacious.timer \
  borg-offsite-astute-critical.timer \
  borg-offsite-check.timer
```

---

## Schedules

- `borg-offsite-audacious.timer` — daily at 14:00 (Persistent + WakeSystem)
- `borg-offsite-astute-critical.timer` — daily at 15:00 (Persistent + WakeSystem)
- `borg-offsite-check.timer` — monthly (Persistent + WakeSystem)

Timers are staggered to avoid simultaneous uploads and network contention.

---

## Notes

- `audacious-home` contains the Borg repo directory from Astute. Restores are two-step.
- `astute-critical` is append-only; do not prune or compact.
- Logs: `journalctl -u borg-offsite-*.service`
- Patterns in `etc/borg-offsite/` are unused (legacy).
