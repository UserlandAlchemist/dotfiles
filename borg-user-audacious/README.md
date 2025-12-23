# borg-user-audacious

Per-user BorgBackup configuration for audacious.

This package defines the user-level environment and non-secret configuration
required by the systemd timers from `root-backup-audacious`.

Contents:
- `.config/borg/env` — systemd-style environment variables for Borg
- `.config/borg/env.sh` — shell wrapper to load `.config/borg/env` interactively
- `.config/borg/patterns` — include and exclude rules for `borg create`
  (referenced by `--patterns-from`)

Not included in git:
- `.config/borg/passphrase` — the encryption key for this host’s Borg
  repository. This file must exist locally at `~/.config/borg/passphrase`
  so that backup timers can run non-interactively.

---

## Environment design

Systemd reads `.config/borg/env` directly using:

    EnvironmentFile=%h/.config/borg/env

This file uses plain `KEY=VALUE` syntax (no `export` or quotes) compatible with
systemd units. It defines values such as:

    BORG_REPO=ssh://borg@astute/srv/backups/audacious-borg
    BORG_PASSCOMMAND=cat /home/alchemist/.config/borg/passphrase
    BORG_RSH=ssh -i /home/alchemist/.ssh/audacious-backup -T
    BORG_NONINTERACTIVE=1

When running Borg manually in a shell, use the helper script:

    ~/.config/borg/env.sh borg list

This wrapper reads the same file, exports its variables, and runs the command.

---

## Security notice

The `passphrase` file is sensitive and unique to this host.  
It is not tracked in git and should never be committed or shared.

If this dotfiles repository is cloned to another host, you must either
create a new `~/.config/borg/passphrase` for that host, or omit this
package entirely if the host should not access the same repository.

Recommended permissions:

    chmod 700 ~/.config/borg
    chmod 600 ~/.config/borg/passphrase
    chmod 600 ~/.config/borg/env
    chmod 700 ~/.config/borg/env.sh

---

## Deploy

1. Ensure the Borg configuration directory exists:

        mkdir -p ~/.config/borg
        chmod 700 ~/.config/borg

2. Stow the non-secret configuration:

        cd ~/dotfiles
        stow borg-user-audacious

   This will create:

       ~/.config/borg/patterns -> dotfiles/borg-user-audacious/.config/borg/patterns
       ~/.config/borg/env -> dotfiles/borg-user-audacious/.config/borg/env
       ~/.config/borg/env.sh -> dotfiles/borg-user-audacious/.config/borg/env.sh

3. Create or copy the Borg repository passphrase locally:

        editor ~/.config/borg/passphrase
        chmod 600 ~/.config/borg/passphrase

4. Verify all files exist:

        ~/.config/borg/patterns     (symlink from repo)
        ~/.config/borg/env          (symlink from repo)
        ~/.config/borg/env.sh       (symlink from repo)
        ~/.config/borg/passphrase   (local secret)

---

## Used by

The following systemd units depend on these files:

- `borg-backup.service`
- `borg-check.service`
- `borg-check-deep.service`

Each unit references the environment file:

    EnvironmentFile=%h/.config/borg/env

and runs the wake script `/usr/local/lib/borg/wait-for-astute.sh` before
any Borg command to ensure the target system (`astute`) is reachable.

---

## Related packages

- `root-backup-audacious/` — systemd service and timer units that invoke Borg
- `ssh-audacious/` — SSH configuration containing the backup key used by Borg
