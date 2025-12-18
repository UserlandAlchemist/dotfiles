# etc-power-astute

Astute power-management policy and supporting infrastructure.

## Contents

- nas-inhibit.service
  Systemd service that asserts a sleep inhibitor while the NAS is in use.

- nas-inhibit.sudoers (template)
  Sudo rule allowing the Audacious user to start/stop the inhibitor remotely.

## Why sudoers is not stowed

Files in /etc/sudoers.d must:
- be owned by root:root
- have mode 0440
- not be writable by non-root users

When managed via GNU Stow, sudoers files become symlinks into the
dotfiles working tree. Enforcing runtime ownership and permissions
then mutates the Git-tracked file, leaving the working tree dirty.

To avoid this, sudoers rules are tracked as templates and installed
explicitly via install.sh.

This mirrors how configuration management systems (Ansible, Puppet,
etc.) handle sudoers.

## Installation (Astute)

From ~/dotfiles on Astute:

    sudo ./etc-power-astute/install.sh

This will:
- stow systemd units
- install the sudoers rule with correct ownership and mode
- reload systemd
- validate sudoers syntax

## Operational use

The NAS inhibitor is controlled remotely from Audacious via:

    sudo systemctl start nas-inhibit.service
    sudo systemctl stop nas-inhibit.service

The inhibitor automatically expires via RuntimeMaxSec.

