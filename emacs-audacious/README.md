 emacs-audacious

Emacs configuration for **audacious**, using an XDG-style layout.

This package provides:
- `~/.emacs` — a tiny loader shim
- `~/.config/emacs/` — the actual configuration (init file, themes, etc.)

Runtime and cache directories under `~/.emacs.d/` are intentionally left
**untracked** and will be created automatically by Emacs on first launch.

---

## Layout

    emacs-audacious/
    ├── .emacs
    └── .config
        └── emacs
            ├── init.el
            └── themes/
                └── amiga-dark-theme.el

---

## Deploy

Run as your user:

    cd ~/dotfiles
    stow emacs-audacious

Emacs will then load configuration from `~/.config/emacs/` via the shim at
`~/.emacs`.

---

## Notes

- The `~/.emacs` file simply redirects Emacs to load from `~/.config/emacs/init.el`.
  Example content:

      ;; Load real config from ~/.config/emacs/
      (load (expand-file-name "init.el" "~/.config/emacs/"))

- Emacs will automatically create `~/.emacs.d/` for native compilation and
  autosaves. This directory is machine-local and not tracked by git.
- You can safely add `.emacs.d/` and `*.eln` to `.gitignore` to avoid noise.
- This setup works with Emacs 28 and newer, including native-compilation builds
  shipped in Debian Trixie.

---

## Rationale

Using an XDG-style layout keeps versioned configuration (`~/.config/emacs`)
separate from transient runtime data (`~/.emacs.d/`), improving portability and
avoiding unwanted git churn on each system.
