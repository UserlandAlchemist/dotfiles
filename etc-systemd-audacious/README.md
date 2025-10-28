# etc-systemd-audacious

Systemd units that are not strictly power-related, for **audacious**.

Currently provides:
- efi-sync.service
- efi-sync.path

These units keep the primary EFI System Partition (/boot/efi) mirrored to a secondary backup ESP (/boot/efi-backup) whenever `kernel-install` updates unified kernel images (UKIs).

## Deploy

Run as root:

    sudo stow --target=/ etc-systemd-audacious
    sudo systemctl daemon-reload
    sudo systemctl enable --now efi-sync.path

## Requirements

- Two EFI partitions mounted at:
    /boot/efi
    /boot/efi-backup
- `rsync` installed and available in PATH
- Both partitions must be writable by root
- `kernel-install` hooks must update UKIs under /boot or /efi as expected

## Notes

- The `.path` unit triggers synchronization automatically whenever files under `/boot/efi/EFI/Linux/` change.
- You can manually sync at any time with:

      sudo systemctl start efi-sync.service

- To disable automatic syncing but keep manual use:

      sudo systemctl disable --now efi-sync.path
