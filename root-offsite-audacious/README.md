# root-offsite-audacious

Off-site BorgBackup push from Audacious to BorgBase.

Backs up:
- Audacious home data → `audacious-home` (append-only access)

**Critical:** Append-only SSH key assignment is required for ransomware protection. See `docs/offsite-backup.md` for verification, repo initialization, and restore steps.

---

## Prerequisites

1. BorgBackup installed (borg 1.x).
2. BorgBase SSH key installed on Audacious:
   - Private key: `/root/.ssh/borgbase-offsite-audacious`
   - Public key uploaded to BorgBase.
3. Passphrase file created (root-only):
   - `/root/.config/borg-offsite/audacious-home.passphrase`
4. BorgBase repo created:
   - audacious-home (append-only access)
5. Audacious Borg patterns stowed for `alchemist`:
   - `/home/alchemist/.config/borg/patterns`

---

## Deploy

Install systemd units as real files:

```bash
sudo /home/alchemist/dotfiles/root-offsite-audacious/install.sh
```

Enable timers:

```bash
sudo systemctl enable --now \
  borg-offsite-audacious.timer \
  borg-offsite-check.timer
```

---

## Schedules

- `borg-offsite-audacious.timer` — daily at 14:00 (Persistent + WakeSystem)
- `borg-offsite-check.timer` — monthly (Persistent + WakeSystem)

---

## Notes

- `audacious-home` uses append-only access; do not prune or compact.
- Logs: `journalctl -u borg-offsite-*.service`
