# borg-user-audacious

Per-user BorgBackup configuration for **audacious**.

This package defines the non-secret parts of the BorgBackup setup used by the
systemd timers from `backup-systemd-audacious`.

Contents:
- `.config/borg/patterns` — include/exclude rules for `borg create`
  (referenced by `--patterns-from`)

Not included in git:
- `.config/borg/passphrase` — the encryption key for this host’s Borg
  repository. This file must exist locally at `~/.config/borg/passphrase`
  so that backup timers can run non-interactively.

## Security notice

The `passphrase` file is sensitive and unique to this host.  
It is **not** tracked in git, and should never be committed or shared.

If this dotfiles repository is cloned to another host, you must:
- create a new `~/.config/borg/passphrase` for that host, or
- omit this package entirely if the host should not access the same repository.

## Deploy

1. Ensure the Borg configuration directory exists:

    mkdir -p ~/.config/borg
    chmod 700 ~/.config/borg

2. Stow the non-secret config:

    cd ~/dotfiles
    stow borg-user-audacious

   This will create:

       ~/.config/borg/patterns -> dotfiles/borg-user-audacious/.config/borg/patterns

3. Create or copy your Borg repository passphrase locally (do **not** commit it):

    editor ~/.config/borg/passphrase
    chmod 600 ~/.config/borg/passphrase

4. Verify both files exist:

    ~/.config/borg/patterns     (symlink from repo)
    ~/.config/borg/passphrase   (local secret, 600 permissions)

## Used by

The following systemd units depend on these files:

- `borg-backup.service`
- `borg-check.service`
- `borg-check-deep.service`

Ensure both `patterns` and `passphrase` exist before enabling these timers.
