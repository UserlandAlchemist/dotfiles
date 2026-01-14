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
2. Unit files parse cleanly (when tools are present).
3. Shellspec specs run when `shellspec` is installed.

Sudoers and nftables syntax checks run in the privileged suite.

---

## Tooling Installation (Debian)

Install the unprivileged tooling with apt, then install `shellspec` and `mdl`
locally.

Steps:

1. Install apt packages:

    ```bash
    sudo apt install shellcheck shfmt ruby ruby-dev
    ```

2. Install shellspec (user-local):

    ```bash
    git clone https://github.com/shellspec/shellspec ~/.local/share/shellspec
    ln -s ~/.local/share/shellspec/shellspec ~/.local/bin/shellspec
    ```

3. Install markdown lint (user-local):

    ```bash
    GEM_SPEC_CACHE="$HOME/.local/share/gem-cache" \
      gem install --user-install mdl
    ```

4. Ensure the gem bin dir is on `PATH`:

    ```bash
    export PATH="$HOME/.local/share/gem/ruby/3.3.0/bin:$PATH"
    ```

Expected results:

1. `shellcheck`, `shfmt`, and `shellspec` report versions.
2. `mdl --version` runs without a path error.

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

Shellspec is the BDD framework for scripted behavior checks.

1. Install `shellspec` using your preferred package source.
2. Run the specs:

    ```bash
    shellspec
    ```

The unprivileged suite runs `shellspec` automatically when it is available.

---

## Change Requirements

1. For behavior changes, add or update Shellspec specs (or other relevant
   tests) and review coverage for the affected package/host.
2. Keep unprivileged and privileged suites clean after each change.
3. When editing Markdown, run markdown lint and resolve findings.

---

## Backup Verification (Privileged)

Run after changing borg tooling, backup units, or patterns files.

1. Execute the backup verification script:

    ```bash
    sudo ./scripts/test-backups.sh
    ```

2. Optional: include a patterns dry run (scans sources without writing an
   archive):

    ```bash
    sudo BACKUP_VERIFY_PATTERNS=1 ./scripts/test-backups.sh
    ```

3. Optional: skip offsite checks if offline:

    ```bash
    sudo CHECK_OFFSITE=0 ./scripts/test-backups.sh
    ```

Expected results:

1. Local repository listing completes successfully.
2. Offsite repository listings complete successfully (unless skipped).
3. Patterns dry run completes when enabled.

---

## Power Management Verification

Run after changing swayidle or idle-shutdown logic. Use the stubs in
`spec/support/bin` to avoid real shutdowns.

1. Verify inhibitor handling (no poweroff):

    ```bash
    PATH="$PWD/spec/support/bin:$PATH" \
      SYSTEMD_INHIBIT_OUTPUT=shutdown \
      JELLYFIN_CHECK_REMOTE=0 \
      MEDIA_WINDOW_SEC=1 CHECK_INTERVAL_SEC=1 \
      ./bin-audacious/.local/bin/idle-shutdown.sh
    ```

2. Verify shutdown path (stubbed poweroff output):

    ```bash
    PATH="$PWD/spec/support/bin:$PATH" \
      JELLYFIN_CHECK_REMOTE=0 \
      MEDIA_WINDOW_SEC=0 BUSY_WINDOW_SEC=0 \
      SYSTEMCTL_POWEROFF_OUTPUT=poweroff \
      ./bin-audacious/.local/bin/idle-shutdown.sh
    ```

Expected results:

1. Inhibitor test exits without triggering `poweroff`.
2. Shutdown test emits the stubbed `poweroff` output.

---

## Coverage Map

Unprivileged suite:

- Shell linting and format checks for tracked shell scripts (including
  executable shebang scripts).
- Systemd unit file verification against repo units for the current host.
- Syntax checks for JSONC configs.
- Shellspec specs for key scripts and regressions.

Privileged suite:

- Host install script regression run.
- Installed systemd unit verification and daemon reload.
- Installed `sudoers` and `nftables` syntax checks.

Notes:

- Hardware-specific and live service behavior still requires manual validation.
- Keep `scripts/test-dotfiles.sh` green before applying changes.
