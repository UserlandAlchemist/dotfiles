# ssh-audacious

Manages `~/.ssh/config` for **audacious**.

- Only the SSH config file is tracked.
- Keys, known_hosts, and other sensitive files are *never* committed to git.

## Deploy

Run as your user (not root):

    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    cd ~/dotfiles
    stow ssh-audacious

    chmod 600 ~/.ssh/config

This ensures the `~/.ssh` directory exists as a real directory before stowing,
preventing it from being replaced by a symlink if it doesn’t already exist.

## Notes

- The permissions above are important for OpenSSH to accept the configuration.
- You can safely manage multiple host-specific SSH configs under different
  `ssh-*` stow packages; each should contain only its own `config` file.
