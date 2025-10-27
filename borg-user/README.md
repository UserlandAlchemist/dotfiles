# backup-systemd

Systemd timers and services for unattended BorgBackup.

Installs:
- borg-backup.service / .timer
- borg-check.service / .timer
- borg-check-deep.service / .timer

These run regular backups and repository integrity checks.

## Deploy

Run as root:

    sudo stow --target=/ backup-systemd
    sudo systemctl daemon-reload
    sudo systemctl enable --now \
        borg-backup.timer \
        borg-check.timer \
        borg-check-deep.timer

Prereqs:
- Package "borgbackup" is installed
- The user backup config (~/.config/borg/) has already been deployed from borg-user/
- ~/.config/borg/passphrase exists for that user so Borg can run non-interactively
