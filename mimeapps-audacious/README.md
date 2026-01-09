# mimeapps-audacious

Default application associations (MIME handlers).

Provides baseline `mimeapps.list` defining preferred default applications
(browser, terminal, editor, etc.) for fresh setup.

## Important

Do **not** stow this package directly.

Most desktop environments and tools (e.g., web browsers, file managers) will
automatically update `~/.config/mimeapps.list` to record user choices. If this
file is a symlink into your dotfiles repository, those changes will modify the
repo unintentionally.

## Deploy

Instead of stowing, copy it once:

```bash
cp ~/dotfiles/mimeapps-audacious/.config/mimeapps.list ~/.config/mimeapps.list
```

After that, `~/.config/mimeapps.list` should remain a **regular file** owned by
the user. It will evolve over time as this host's application defaults change.

If you ever want to reset to the baseline, simply re-copy this file.
