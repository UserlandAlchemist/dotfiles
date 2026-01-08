# root-offsite-astute

Off-site BorgBackup push from Astute to BorgBase.

Backs up:
- `/srv/nas/lucii` and `/srv/nas/bitwarden-exports` → `astute-critical` (append-only access)

**Critical:** Append-only SSH key assignment is required for ransomware protection. See `docs/offsite-backup.md` for verification, repo initialization, and restore steps.

---

## Prerequisites

1. BorgBackup installed (borg 1.x).
2. BorgBase SSH key installed on Astute:
   - Private key: `/root/.ssh/borgbase-offsite-astute`
   - Public key uploaded to BorgBase.
3. Passphrase files created (root-only):
   - `/root/.config/borg-offsite/astute-critical.passphrase`
4. BorgBase repos created:
   - astute-critical (append-only access)

---

## Deploy

Install systemd units as real files:

```bash
sudo /home/alchemist/dotfiles/root-offsite-astute/install.sh
```

Enable timers:

```bash
sudo systemctl enable --now \
  borg-offsite-astute-critical.timer \
  borg-offsite-check.timer
```

---

## Schedules

- `borg-offsite-astute-critical.timer` — weekly at 15:00 (Persistent + WakeSystem)
- `borg-offsite-check.timer` — monthly (Persistent + WakeSystem)

Timers are staggered to avoid simultaneous uploads and network contention.

---

## Notes

- `astute-critical` uses append-only access; do not prune or compact.
- Logs: `journalctl -u borg-offsite-*.service`
