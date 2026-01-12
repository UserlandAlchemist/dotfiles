# Testing

Run automated checks after editing configs or scripts. Use the unprivileged
suite for fast regression checks and the privileged suite for host-level
validation.

---

## Quick Start (Unprivileged)

1. Run the suite from the repo root:

    ```bash
    ./scripts/test-dotfiles.sh
    ```

2. Review warnings and failures. Resolve failures before applying changes.

Expected results:

1. Shell linting and formatting checks complete.
2. Unit files, sudoers, and nftables parse cleanly (when tools are present).
3. Shellspec specs run when `shellspec` is installed.

---

## Privileged Checks

Run privileged checks after installing or updating host packages.

1. Execute the privileged suite:

    ```bash
    sudo ./scripts/test-dotfiles-privileged.sh
    ```

2. Review service health and syntax checks.

Expected results:

1. Install scripts complete for the current host.
2. `systemd` reloads cleanly and no units are failed.
3. `sudoers` and `nftables` configs parse cleanly.

---

## BDD Specs (Shellspec)

Shellspec is optional but recommended for scripted behavior checks.

1. Install `shellspec` using your preferred package source.
2. Run the specs:

    ```bash
    shellspec
    ```

The unprivileged suite runs `shellspec` automatically when it is available.

---

## Coverage Map

Unprivileged suite:

- Shell linting and format checks for tracked scripts.
- Systemd unit file verification against repo units.
- Syntax checks for nftables, sudoers, and JSONC configs.
- Shellspec specs for key scripts and regressions.

Privileged suite:

- Host install script regression run.
- Installed systemd unit verification and daemon reload.
- Installed `sudoers` and `nftables` syntax checks.

Notes:

- Hardware-specific and live service behavior still requires manual validation.
- Keep `scripts/test-dotfiles.sh` green before applying changes.
