# Claude ↔ Codex Handoff Document

**Last updated:** 2025-12-22 19:35 by Claude
**Session context:** Ongoing dotfiles cleanup and documentation alignment

---

## Current State

### Uncommitted Changes (Codex's recent work - AWAITING CLAUDE REVIEW & TEST)
- `nas-audacious/.config/systemd/user/astute-nas.service` - Refactored to use SSH config
- `ssh-audacious/.ssh/config` - Added astute-nas host entry
- `docs/audacious/DRIFT-CHECK.md` - New drift checking procedure

**Status:** Codex made these changes between sessions. Changes look structurally good but need Claude testing before commit.

### Recently Committed (Codex's work, user committed)
- `AGENTS.md` updates (commit 6e81dff) - Aligned agent guidance documentation
- Various doc improvements through commit 949f3a1

**Claude's previous session work (all committed):**
- Created check-drift.sh mechanism
- Rewrote INSTALL.audacious.md in handbook style
- Updated installed-software.audacious.md
- Fixed NAS inhibitor permissions
- Various system documentation improvements

### Active Todo List

**PENDING (requires Claude - system operations/testing):**
1. **Fix ssh-astute to check reachability before WOL** — Currently sends WOL even if host is up
2. **Investigate lingering sessions preventing Astute sleep** — SSH sessions may not be closing properly
3. **Test and commit NAS service changes** — Codex made good changes, need validation

**PENDING (suitable for Codex - documentation/analysis):**
4. **Rewrite INSTALL.astute.md in handbook style** — Follow INSTALL.audacious.md as template
5. **Rewrite RECOVERY/RESTORE docs in handbook style** — Consistent style across all recovery docs
6. **Review vanilla Trixie divergence** — Document where we diverge from stock Debian

**PENDING (requires collaboration):**
7. **Standardize stow package naming** — `root-*` packages use inconsistent naming (root-concern-host vs root-host-concern)

---

## Tasks Suitable for Codex (Safe for Autonomous Work)

When Claude hits usage limits, Codex can work on these independently:

### Documentation Tasks
- Rewrite INSTALL.astute.md in BSD handbook style (similar to INSTALL.audacious.md)
- Rewrite RECOVERY.audacious.md, RESTORE.audacious.md in handbook style
- Document vanilla Trixie divergences in a structured way
- Create drift check documentation for other hosts (astute, artful)

### Analysis Tasks
- Search codebase for undocumented features/scripts
- Check for broken symlinks or references
- Review .gitignore completeness (secrets, cache files)
- Audit bash functions for error handling

### Low-Risk Edits
- Fix typos, formatting consistency in markdown files
- Add comments to complex bash scripts
- Improve existing documentation clarity (without changing technical content)

---

## Tasks Requiring Claude (DO NOT ATTEMPT)

These require system access, testing, or judgment calls:

- Any changes to systemd services/timers (need testing with daemon-reload)
- Any changes to scripts in bin-audacious/.local/bin/ (need execution testing)
- SSH configuration changes (need connectivity testing)
- Stow package reorganization (need actual stow operations)
- Git commits (Claude does final review and commits)
- Any `sudo` commands or system state changes
- Testing NAS wake/sleep functionality
- Testing backup functionality

---

## Style Guide for Codex

### Documentation Standards

**Tone:**
- Terse, technical, imperative
- BSD handbook style: clear numbered steps, "do X, then Y"
- No marketing language or enthusiasm
- Focus on "why" in prose, "what" in code

**Formatting:**
- Use `---` horizontal rules to separate major sections
- Code blocks: triple backticks with language hint
- Commands: show as `code` or in blocks, never as plain text
- File paths: always absolute when clarity matters
- Lists: `-` for unordered, numbered for sequential steps

**Structure (for INSTALL docs):**
```
# Title

Brief purpose statement (1-2 sentences).

---

## §1 First Major Step

Clear description of what and why.

Steps:
1. First command
2. Second command

Expected result: [what you should see]

---

## §2 Next Major Step
[continue...]
```

### Code/Config Standards

**Bash scripts:**
- Always `#!/usr/bin/env bash`
- Always `set -euo pipefail` for safety
- Prefer explicit over clever
- No bashisms unless intentional
- Comment complex logic, not obvious operations

**Systemd units:**
- Absolute paths for all executables
- Comments above each directive explaining "why"
- Use Dependencies correctly (After=, Requires=, Wants=)

**Stow packages:**
- One concern per package
- Never mix user and system scopes
- Match naming: `<tool>-<host>` or `root-<concern>-<host>`

### Commit Messages (for reference, Claude will commit)

```
component: short imperative summary

Optional longer explanation of why this change matters.
Focus on motivation and context, not what the diff shows.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: [Claude Sonnet 4.5 | Codex] <noreply@anthropic.com>
```

---

## Handoff Protocol

### When Codex Completes Work

**Create a handoff summary in this format:**

```markdown
## Handoff: Codex → Claude
**Date:** YYYY-MM-DD HH:MM
**Goal:** [One sentence: what were you trying to accomplish?]

### Scope
Files changed:
- path/to/file1 — brief description
- path/to/file2 — brief description

### Work Completed
- [x] Task 1 description
- [x] Task 2 description
- [ ] Task 3 — NOT completed because [reason]

### Assumptions Made
- Assumption 1 about system state
- Assumption 2 about user preference

### Commands Run (if any)
```bash
command1  # output: [key result]
command2  # output: [key result]
```

### Diff Summary
Brief description of each change and rationale.

### Risks/Unknowns
- Thing 1 that needs verification
- Thing 2 that might break

### Tests Needed
- [ ] Test X to verify Y
- [ ] Test Z to verify W

### Documentation Updated
- [ ] Updated file X
- [ ] Created file Y
- [ ] No docs needed because [reason]
```

### When Claude Resumes

Claude will:
1. Review handoff summary
2. Test changes if needed
3. Commit or request revisions
4. Update HANDOFF.md with new state

---

## Repository Context (Quick Reference)

### The Machines
- **audacious** (primary workstation): ZFS RAID1, Sway/Wayland, aggressive power management
- **astute** (NAS): Low-power server, ZFS mirror at /srv/nas, suspend-on-idle
- **artful** (cloud): Hetzner VPS, public services
- **steamdeck**: Portable, minimal dotfile coverage

### Critical Subsystems
- **NAS wake-on-demand**: audacious wakes astute via WOL, mounts NFS, uses systemd inhibitors
- **Idle shutdown**: 20min idle → shutdown with smart detection (media playing, remote playback)
- **BorgBackup**: audacious → astute encrypted backups, multiple daily
- **Dual EFI**: Both NVMe drives bootable with auto-sync via systemd.path

### Philosophy
- **Repo-first**: Plain text config, no daemons/wrappers
- **Per-host isolation**: No shared config that breaks single-host recovery
- **Vanilla Debian preference**: Minimize divergence from stock Debian
- **Fail-open**: Remote checks shouldn't block local operations
- **Documentation first**: Changes affecting recovery must update docs

### Files to Never Modify
- SSH keys (ssh-*/.ssh/id_*)
- Borg passphrases (borg-user-*/.config/borg/passphrase)
- Known_hosts, API tokens
- Anything in .gitignore

---

## Current Session Notes

**What we were doing:**
- Completed documentation cleanup for audacious (INSTALL, installed-software)
- Created drift checking mechanism (check-drift.sh + DRIFT-CHECK.md)
- Codex refactored NAS service to use SSH config (good work, needs testing)
- Outstanding: fix ssh-astute script, investigate astute sleep issues, replicate doc style to other hosts

**Next logical steps:**
1. Claude: Test NAS changes, commit if good
2. Claude: Fix ssh-astute reachability check
3. Codex: Rewrite INSTALL.astute.md in handbook style
4. Collaboration: Standardize root-* package naming

**Open questions:**
- None currently

---

**END OF HANDOFF DOCUMENT**
