#!/usr/bin/env bash
# Check for drift between documented and installed packages

set -euo pipefail

DOTFILES="${HOME}/dotfiles"
DOC="${DOTFILES}/docs/audacious/installed-software.audacious.md"

if [[ ! -f "$DOC" ]]; then
    echo "Error: Cannot find $DOC"
    exit 1
fi

# Extract documented packages (lines starting with "- packagename")
# Skip special cases: heroic (local .deb), comments, headers
documented=$(grep '^- [a-z0-9]' "$DOC" | \
    grep -v '(local .deb)' | \
    sed 's/^- \([a-z0-9+.][a-z0-9+.-]*\).*/\1/' | \
    sort -u)

# Get actually installed packages marked manual
installed=$(apt-mark showmanual | sort -u)

# Find differences
not_installed=$(comm -23 <(echo "$documented") <(echo "$installed"))
not_documented=$(comm -13 <(echo "$documented") <(echo "$installed"))

# Report
if [[ -z "$not_installed" ]] && [[ -z "$not_documented" ]]; then
    echo "✓ No drift detected"
    echo "  Documented: $(echo "$documented" | wc -l) packages"
    echo "  Installed:  $(echo "$installed" | wc -l) packages"
    exit 0
fi

echo "⚠ Drift detected between documentation and system"
echo

if [[ -n "$not_installed" ]]; then
    echo "Documented but NOT installed:"
    echo "$not_installed" | sed 's/^/  - /'
    echo
fi

if [[ -n "$not_documented" ]]; then
    echo "Installed but NOT documented:"
    echo "$not_documented" | sed 's/^/  - /'
    echo
fi

echo "Total documented: $(echo "$documented" | wc -l)"
echo "Total installed:  $(echo "$installed" | wc -l)"
echo
echo "To update timestamp: edit $DOC"
exit 1
