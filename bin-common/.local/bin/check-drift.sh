#!/usr/bin/env bash
# Check for drift between documented and installed packages

set -euo pipefail

DOTFILES="${HOME}/dotfiles"

doc_arg="${1:-}"
if [[ -n "$doc_arg" ]]; then
    if [[ "$doc_arg" == */* || "$doc_arg" == *.md ]]; then
        DOC="$doc_arg"
    else
        DOC="${DOTFILES}/docs/${doc_arg}/installed-software.${doc_arg}.md"
    fi
else
    host="$(hostname -s)"
    DOC="${DOTFILES}/docs/${host}/installed-software.${host}.md"
fi

if [[ ! -f "$DOC" ]]; then
    echo "Error: Cannot find $DOC"
    exit 1
fi

# Extract documented packages (lines starting with "- packagename")
# Limit to APT-managed sections and skip local deb markers.
documented=$( { awk '
    BEGIN { in_apt = 1 }
    /^## Non-APT Software/ { in_apt = 0 }
    in_apt { print }
' "$DOC" | \
    grep '^- [a-z0-9]' | \
    grep -v '(local deb' || true; } | \
    sed 's/^- \([a-z0-9+.][a-z0-9+.-]*\).*/\1/' | \
    sort -u)

# Local deb entries should not be part of APT drift checks.
excluded=$( { awk '
    BEGIN { in_apt = 1 }
    /^## Non-APT Software/ { in_apt = 0 }
    in_apt { print }
' "$DOC" | \
    grep '^- [a-z0-9]' | \
    grep -i 'local deb' || true; } | \
    sed 's/^- \([a-z0-9+.][a-z0-9+.-]*\).*/\1/' | \
    sort -u)

# Get actually installed packages
installed=$(apt-mark showmanual | sort -u)
if [[ -n "$excluded" ]]; then
    installed=$(comm -23 <(echo "$installed") <(echo "$excluded"))
fi

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
