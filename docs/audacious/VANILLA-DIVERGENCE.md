# Debian Trixie Divergence (Audacious)

Factual record of where Audacious diverges from stock Debian Trixie defaults. Focus is on direct edits/overrides of system defaults and recovery impact.

---

## Bash profile wrappers + drop-ins
**Location:** `~/.bashrc`, `~/.bash_profile`, `~/.bashrc.d/*`, `~/.bash_profile.d/*` (via `bash-audacious/`)
**Divergence:** Uses thin wrappers that source Debian defaults and then host-specific drop-ins.
**Reason:** Preserve Debian defaults while layering host-specific prompt, env, and helpers.
**Vanilla path:** Debian uses `/etc/skel/.bashrc`, `/etc/profile`, and `/etc/bash.bashrc` without user drop-ins.
**Recovery impact:** Requires stow deployment to keep drop-ins; defaults remain intact if wrappers are missing.

---

## Systemd units (user + system)
**Location:** `~/.config/systemd/user/` and `/etc/systemd/system/` via stow packages (e.g., `nas-audacious`, `root-power-audacious`, `root-backup-audacious`)
**Divergence:** Custom units override or extend default behavior (NAS wake/inhibit, power tuning, backup timers, EFI sync).
**Reason:** Host-specific orchestration and power/backup policies.
**Vanilla path:** Debian ships defaults in `/usr/lib/systemd/system/` with no host-specific units.
**Recovery impact:** Requires re-stow and `systemctl daemon-reload`; missing units change NAS, power, and backup behavior.

---

## Custom scripts in /usr/local/libexec
**Location:** `/usr/local/libexec/*` via `root-*` packages
**Divergence:** Host-specific scripts (NAS inhibit, idle checks, etc.) are installed outside Debian packaging.
**Reason:** Keep automation explicit and repo-managed.
**Vanilla path:** `/usr/local/libexec` is empty on a stock install.
**Recovery impact:** Missing scripts break systemd unit ExecStart/ExecStop targets.

---

## APT repository additions
**Location:** `/etc/apt/sources.list.d/jellyfin.list`, `/etc/apt/sources.list.d/prismlauncher.list`
**Divergence:** Adds third-party repositories for Jellyfin and Prism Launcher.
**Reason:** Packages not available in stock Debian repos.
**Vanilla path:** Only Debian `trixie`, `trixie-updates`, and `trixie-security` entries.
**Recovery impact:** Without these repos, installed packages cannot be reinstalled or updated.

---

## Manual keyring install (Prism Launcher)
**Location:** `/usr/share/keyrings/prismlauncher-archive-keyring.gpg`
**Divergence:** Keyring is manually installed (not owned by a Debian package).
**Reason:** Required to authenticate the Prism Launcher repo.
**Vanilla path:** No Prism keyring present.
**Recovery impact:** Repo entry will fail without recreating the keyring file.

---

## Boot stack: systemd-boot + UKI
**Location:** `/boot/efi/EFI/Linux/*.efi`, `/etc/kernel/install.conf`, `/etc/kernel/uki.conf`
**Divergence:** Uses systemd-boot with Unified Kernel Images (UKI), not GRUB + separate initrd.
**Reason:** Simplifies boot chain for ZFS with signed UKI and dual-ESP sync.
**Vanilla path:** Debian defaults to GRUB with separate initrd.
**Recovery impact:** Rebuild must install systemd-boot and regenerate UKIs; GRUB will not reflect current boot setup.

---

## ZFS root instead of ext4
**Location:** `rpool` with datasets under `/` and `/home`
**Divergence:** Root filesystem on encrypted ZFS mirror, not ext4.
**Reason:** Snapshotting, integrity, and mirror reliability.
**Vanilla path:** ext4 root on a single disk.
**Recovery impact:** Requires ZFS tooling in initramfs and special import/mount steps.

---

## Kernel command line via UKI
**Location:** `/etc/kernel/cmdline`
**Divergence:** Custom kernel parameters stored in UKI cmdline.
**Reason:** Ensure ZFS root and host tuning are applied consistently.
**Vanilla path:** GRUB-managed cmdline in `/etc/default/grub`.
**Recovery impact:** Rebuild must restore `/etc/kernel/cmdline` before generating UKIs.

---

## Power management policy
**Location:** `root-power-audacious` systemd units + udev rules
**Divergence:** Aggressive power tuning, USB autosuspend exceptions, and suspend disabled.
**Reason:** Stability on Audacious hardware and predictable idle shutdown.
**Vanilla path:** Default power settings with suspend enabled.
**Recovery impact:** Without these units, power behavior changes (sleep enabled, different device autosuspend).

---

## Manual /opt installations
**Location:** `/opt/*` (sfizz, zyn-fusion, vcv-rack)
**Divergence:** Manual installs outside Debian packages.
**Reason:** Required versions not available in Debian.
**Vanilla path:** `/opt` typically empty on stock Debian.
**Recovery impact:** Requires manual reinstall steps not covered by apt.
