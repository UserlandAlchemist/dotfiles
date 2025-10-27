# etc-systemd

Systemd units that are not strictly power-related.

Currently provides:
- efi-sync.service
- efi-sync.path

These keep the primary EFI System Partition (/boot/efi) mirrored to a secondary backup ESP (/boot/efi-backup) whenever kernel-install updates unified kernel images (UKIs).

## Deploy

Run as root:

    sudo stow --target=/ etc-systemd
    sudo systemctl daemon-reload
    sudo systemctl enable --now efi-sync.path

Requirements:
- Two EFI partitions mounted at:
    /boot/efi
    /boot/efi-backup
- rsync installed