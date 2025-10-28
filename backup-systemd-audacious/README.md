# backup-systemd-audacious

Systemd timers and services for unattended BorgBackup on host Audacious

Installs:
- borg-backup.service / .timer
- borg-check.service / .timer
- borg-check-deep.service / .timer

These run regular backups and repository integrity checks.

## Deploy

Run as root:

    sudo stow --target=/ backup-systemd-audacious
    sudo systemctl daemon-reload
    sudo systemctl enable --now \
        borg-backup.timer \
        borg-check.timer \
        borg-check-deep.timer

After enabling, you can confirm timers with:

     systemctl list-timers | grep borg

## Prerequisites

Before enabling the timers, make sure all of the following are true:

1. Borg and configuration
    - Package borgbackup is installed on this host
    - The per-user Borg config from borg-user-audacious/ has been stowed for the backup user (alchemist)
    - ~/.config/borg/passphrase exists and contains the repository passphrase (used via BORG_PASSCOMMAND)
    - ~/.config/borg/patterns exists and matches what you want backed up

2. SSH access to the backup target works non-interactively
    - The Borg repository is remote, e.g.
      borg@192.168.x.x:/srv/backups/audacious-borg
    - The service sets BORG_RSH to use a specific SSH key (for example, something like ~/.ssh/audacious-backup-key)
    - That private key:
        - exists on this machine at the expected path
        - is readable by the backup user (alchemist)
        - does not require manual passphrase entry at runtime (either the key is unencrypted, or you’re handling unlocking some other way before the timer runs)
    - The remote host (NAS) has the matching public key in ~borg/.ssh/authorized_keys
    - The remote repo path exists and is writable

3. Network reachability
    - The NAS (“Astute”) is on the network or can be woken via WoL before the timer fires
    - The systemd unit expects to run unattended; if the NAS is offline, the job will fail fast and the timer will try again on the next run

### Sanity check before enabling

Run as the backup user to confirm non-interactive access:

    borg list "$BORG_REPO"

