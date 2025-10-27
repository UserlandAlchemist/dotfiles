# SSH package

Manages `~/.ssh/config`.

- Only the config file is tracked.
- Keys, known_hosts, and other sensitive files are *never* in git.

## Setup

```sh
cd ~/dotfiles
stow ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
```
