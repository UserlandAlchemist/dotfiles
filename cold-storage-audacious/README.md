# Cold Storage Backups (Audacious)

Monthly cold storage snapshots for Audacious with a manual reminder timer.

---

## Layout

Snapshots live on the cold storage mount:

```
/mnt/cold-storage/backups/audacious/
├── latest/              # current mirror
└── snapshots/YYYY-MM/   # monthly snapshots (hard-link based)
```

---

## Manual Run

1. Mount and unlock the cold storage LUKS volume.
2. Run the snapshot script:

```bash
cold-storage-backup.sh
```

Expected result: a new `snapshots/YYYY-MM` directory and refreshed `latest`.

---

## Reminder Timer

Enable a monthly reminder that notifies you to mount and run the backup:

```bash
systemctl --user daemon-reload
systemctl --user enable --now cold-storage-reminder.timer
systemctl --user list-timers | grep cold-storage
```

---

## Retention

The script keeps the most recent 12 monthly snapshots and prunes older ones.
