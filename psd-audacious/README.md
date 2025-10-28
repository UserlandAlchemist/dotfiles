# psd-audacious

Profile-sync-daemon configuration for **audacious**.

Provides `~/.config/psd/psd.conf`.

Runtime files (PID, state, etc.) are stored locally in `~/.config/psd/`
and are not tracked by git.

## Deploy

    mkdir -p ~/.config/psd
    cd ~/dotfiles
    stow psd-audacious

Then enable and start psd:

    systemctl --user enable --now psd.service
