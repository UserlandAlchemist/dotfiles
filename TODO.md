# PROJECT SHIPSHAPE - WORK QUEUE

Updated: 2026-01-12 16:06

Project Shipshape: Dotfiles and configuration management for the Wolfpack. The
Wolfpack: Audacious (workstation), Astute (NAS/server), Artful (cloud), Steam
Deck (portable).

Work queue and session notes for project planning and progress tracking.

────────────────────────────────────────────────────────────────
EXECUTION ORDER (Start Here - Dependency Ordered)
────────────────────────────────────────────────────────────────

Follow this sequence for optimal progress. Tasks are dependency-ordered. Strike
through completed items and move to next.

PHASE 0 - Philosophy & Validation (Week 1-2):

- [x] 1. ~~USERLAND ARCHIVE IMPORT - Review philosophy FIRST (shapes all
  decisions)~~ (docs/principles.md: 5a9f8b6, 604eac1)
- [x] 2. ~~USERLAND PRINCIPLES AUDIT - Audit Shipshape against principles
  (depends on #1)~~ (docs/PRINCIPLES-AUDIT.md: comprehensive review)
- [x] 3. ~~BACKUP AUDIT + RESTORE TESTS - Validate core assumption (can run
  parallel with #2)~~ (docs/BACKUP-AUDIT.md: cc450c9)
- [x] 4. ~~DEVELOP THREAT MODEL - Define security assumptions (depends on: #2
  principles audit)~~ (docs/threat-model.md)

PHASE 1 - Critical Security Fixes (URGENT - 2026-01-06):

- [x] 5. ~~SSH HARDENING (ASTUTE) - Lock SSH to LAN IP (P0-Critical, security
  audit finding)~~
- [x] 6. ~~HOST FIREWALL IMPLEMENTATION - nftables on both hosts (P0-Critical,
  escalated from P1-High)~~

PHASE 2 - Security Audit (After Critical Fixes):

- [x] 7. ~~COMPLETE SECURITY AUDIT - Full audit of services, configs, auth
  policies (depends on: Phase 1 complete)~~ (docs/security-audit.md)
- [x] 8. ~~CRYPTO AUDIT - SSH/GPG key inventory and cleanup (runs alongside
  #7)~~ (included in security-audit.md)

PHASE 3 - Critical Backups & Infrastructure (Week 2-3):

- [x] 9. ~~OFF-SITE BACKUP IMPLEMENTATION - BorgBase repositories (P1-High,
  critical data protection)~~ (commits: 27a4e7c, 623a4c9, 827210e, 5a50238,
  root-borg-astute renamed)
- [x] 10. ~~INSTALL LIBRARY - Idempotent scripts (depends on: Userland
  philosophy)~~ (commits: c135f32, 711e0ed, f36a5a6, 35a89c6)
- [ ] 11. VM TESTING ENVIRONMENT - Safe testing ground (no dependencies)
- [ ] 12. BACKUP INTEGRITY + ALERTING - Add small-file restore check (weekly)
  and minimal alerting for borg/ZFS

PHASE 4 - Documentation & Validation (Week 3-4):

- [ ] 12. UPDATE STRATEGY - Document safe updates (depends on: Userland
  philosophy)
- [ ] 13. DISASTER RECOVERY DRILL - Validate docs (depends on: VM environment,
  backup tests)

PHASE 5 - Protection & Monitoring (Week 4-5):

- [ ] 14. MONITORING & ALERTING - Early warning system (depends on: Userland
  philosophy, threat model)
- [ ] 15. VPN + ENCRYPTED DNS SETUP - Privacy protection (P1-High, UK
  surveillance concerns)

PHASE 6 - Quality of Life (Ongoing, as needed):

- [ ] 16. TORRENTING TO ASTUTE - Offload workstation, better suspend
- [ ] 17. PASSWORD MANAGER REVIEW - Evaluate self-hosting options (Vaultwarden,
  alternatives)
- [ ] 18. MPD + TAGGING WORKFLOW AUDIT - Music library management
- [ ] 19. PROJECT INTEGRAL DOCUMENTATION - DAW context

SCHEDULED (Post 2026-01-12):

- [x] 20. ~~REMOVE LEGACY TOOLING - Transition to single-agent workflow~~

DEFERRED (Prerequisites required):

- [ ] 21. ARTFUL SECURITY HARDENING - Prerequisites for VPS deployment
  (P1-High, blocks Artful activation)

────────────────────────────────────────────────────────────────
RECENT SESSION NOTES
────────────────────────────────────────────────────────────────

## 2026-01-12 - Backup Verification Script

Added a privileged backup verification helper plus docs for backup/power
checks. (47d7db3)

## 2026-01-12 - Gate Unprivileged Checks

Skip sudoers/nft checks in the unprivileged runner and update testing docs.
(bdc54a3)

## 2026-01-12 - Remove SSHD Check

Removed the sshd syntax check from privileged tests and updated testing docs.
(31840f2)

## 2026-01-12 - Shellspec Error Expectations

Aligned shellspec error assertions and made borg offsite runners executable.
(d088b22, 35c1f0f)

## 2026-01-12 - Shellspec Helper Load

Require spec_helper in shellspec options and add a script stub so env-based
specs run target scripts. (c2c6898)

## 2026-01-12 - Shellspec Root Fix

Use SHELLSPEC_PROJECT_ROOT in the spec helper so BDD specs resolve repo paths.
(4a1a63d)

## 2026-01-12 - Shellspec Project Anchor

Added .shellspec to anchor shellspec to the repo root so specs run without
extra flags. (dff7340)

## 2026-01-12 - Privileged SSHD Check Gate

Gate the sshd syntax check in the privileged test runner with an explicit
toggle and auto mode. (10131dc)

## 2026-01-12 - Install Script Path Fix

Fix test install script lookup under sudo by deriving repo root from script
path. (44bfb71)

## 2026-01-12 - Shellcheck Cleanup

Annotated bash fragments for shellcheck and cleaned lint nits in drift and
cold-storage scripts. (a3fe978)

## 2026-01-12 - Shfmt Pass and Test Runner Fixes

Applied shfmt across shell scripts, fixed markdown list nesting in testing docs,
and set the test runner executable bit. (887f390)

## 2026-01-12 - Regression Test Suite Expansion

Added shellspec BDD coverage with stubs, expanded dotfiles checks, and added a
privileged test runner. Documented testing workflow and coverage. (681e890,
9e591be)

## 2026-01-12 - Legacy Tooling Cleanup

Removed legacy tooling references from ignore rules and backup patterns; marked
the cleanup task complete. (564e09a)

## 2026-01-10 - Markdownlint Sweep (All Docs)

Completed a full markdownlint pass across repo READMEs and
package docs; normalized wraps, lists, and code fences. (e8d665e)

## 2026-01-10 - Restore Ordered Lists

Restored sequential numbering in recovery and VM workflow docs. (fc77d6d)

## 2026-01-10 - Markdownlint Spacing Fixes

Markdownlint spacing fixes in core docs. (f35561a, 501b911)

## 2026-01-09 - Install/Recovery Doc Consistency

Aligned install/recovery docs (audacious ZFS altroot to /mnt + verification,
disaster-recovery references, root-borg naming) and fixed astute SSH key path
plus install test package list. (3a9b404)

## 2026-01-09 - Comprehensive Documentation Review

Major documentation restructure across 19 commits. Merged principles.md into
README (228→120 lines), merged identity-policy into AGENTS.md. Consolidated
recovery docs (data-restore→disaster-recovery, renamed secrets-
maintenance→recovery-kit-maintenance). Merged hosts/network-
overview→infrastructure.md. Restructured threat-model.md to in-scope/out-of-
scope format (271→117 lines, 57% reduction). Fixed critical SSH key passphrase
guidance in offsite-backup.md (no passphrase required for automated backups).
Focused vm-architecture.md on immediate install testing (removed
Gentoo/OpenBSD, 542→470 lines). (d41f131..c2a57de, 19 commits)

## 2026-01-08 22:30 - Borg Patterns Fix + Codex Migration Cleanup

Fixed broken borg patterns file (removed sh: prefixes, absolute paths, added
missing exclusions for dev tools/caches). Fixed all Codex offsite migration
bugs (systemd-inhibit flags, audit-secrets passphrases, docs). Audited Codex's
other recent work (all correct). (695a117, 9729229, 91e6391, 59448d6, df9faaf,
8285a97, 0000a94, e4b8315, 0bf7ec5)

## 2026-01-08 19:05 - Astute ZFS Login Warning Fix

Fixed check-zfs login warning to flag missing mounts for encrypted datasets.
(954ba90)

## 2026-01-08 18:45 - Astute Idle Check Inhibitor Filter

Limit idle check to sleep inhibitors only so shutdown inhibitors do not block
suspend. (4ae0103)

## 2026-01-08 17:10 - Offsite Backup Topology Update

Shifted BorgBase audacious-home to Audacious, created root-offsite-audacious,
and kept Astute offsite weekly for critical data. Updated repo ID to j31cxd2v
and refreshed offsite/restore/secrets scripts/docs and key naming. (d7150b3)

## 2026-01-08 16:30 - Astute Networkd Migration Complete

Migrated Astute from ifupdown to systemd-networkd + systemd-resolved. Fixed two
boot timing issues: SSH binding failure (added network-online dependency) and
wait-online hang (limited to enp0s31f6, 30s timeout, IPv4-only). Migration
successful, boot time ~5s for network, SSH accessible immediately. Offsite
backup services already had correct network-online dependencies. (5946f36,
7e6cd26, dc98e39)

## 2026-01-08 00:49 - Documentation Consolidation

Comprehensive audit of all documentation. Fixed terminology inconsistencies (6
"blue USB" → "Secrets USB"). Eliminated 659 lines (23.6%) of duplication and
low-value content. Deleted key-inventory.md (296 lines, content duplicated
elsewhere). Removed implementation tasks from threat-model.md (161 lines).
Removed generic best practices from secrets-recovery.md (72 lines). Changed 9
docs from 600 to 644 permissions. (08c2e89, b72ad04)

## 2026-01-08 00:15 - Agent Coordination File Cleanup

Condensed TODO.md from 2046 to 85 lines (96% reduction). Streamlined AGENTS.md
from 228 to 119 lines. Updated agent instructions to match new condensed
session notes approach. Session notes now 2-3 lines with commit hashes;
detailed work lives in git. (e700360)

## 2026-01-07 23:30 - Install Library (Phase 3, Task #10)

Created lib/install.sh with 9 reusable functions, refactored all 13 root-*
install scripts, eliminated 114 lines (-38% avg). Added 30s timeout to daemon-
reload. Created regression test suite - all 13 packages passed. (c135f32,
711e0ed, f36a5a6, 35a89c6, f1d943c)

## 2026-01-07 22:00 - Disaster Recovery Infrastructure

Fixed Secrets USB missing BorgBase credentials. Created three-tier recovery
strategy (Secrets USB + Trusted Copy + Google Drive) with SHA256 verification.
Renamed "Blue USB" → "Secrets USB" throughout. Created verify/clone/bundle
scripts. Audited both hosts for leftover secrets (all clean). Enhanced
.gitignore protection. (5d560cd, 4da5fa6, 8938021, 6e399dc, da71619, 6a27cf5,
90b1495, 703fd50, 34978d5)

## 2026-01-08 01:13 - Documentation Alignment + Drift Check

Refocused threat model as timeless design doc and trimmed security audit to an
operational log. Removed duplicated overview/offsite documentation. Updated
drift checker to ignore non-APT installs and refreshed Audacious software list
(GTK theme tools); drift check clean. (8b82c4d, dd5fd62, 44ed3e3)

## 2026-01-08 01:17 - Astute Drift Check

Confirmed jellyfin-ffmpeg7 and zfs-zed are installed on Astute, removed nfs-
common from inventory, and refreshed drift-check date. (ec48d44)

## 2026-01-08 01:25 - Drift Check Script Shared

Moved check-drift.sh into bin-common with host-aware behavior and updated docs
to reference the shared tool. (3e7449a)

## 2026-01-08 01:28 - Drift Check Script Fix

Hardened check-drift.sh to tolerate empty local-deb matches. (12a3528)

## 2026-01-08 01:29 - Astute Drift Check Refinement

Adjusted Astute drift checks to compare against all installed packages using
dpkg-query. (28817ce)

## 2026-01-08 01:35 - Drift Check Unification

Switched check-drift.sh back to apt-mark showmanual for all hosts after
normalizing Astute manual marks. (0637292)

## 2026-01-08 01:38 - Astute Firmware Inventory

Recorded intel-microcode and firmware-amd-graphics in the Astute software list
after marking them manual. (fdf9667)

## 2026-01-08 01:39 - Astute Manual Package Tracking

Added nano, nftables, and tasksel meta packages to the Astute software
inventory after marking them manual. (51aaa91)

## 2026-01-08 01:41 - Astute Install List Update

Added nano, nftables, firmware/microcode, and tasksel meta packages to the
Astute base install list; removed nfs-common. (778039c)

## 2026-01-08 01:42 - Astute Utility Additions

Added fdisk, dhcpcd-base, and usbutils to the Astute inventory and install list
after marking them manual. (f25a215)

## 2026-01-08 01:44 - Astute Tasksel Cleanup

Removed task-english from the Astute inventory and install list after marking
it auto. (3a125ce)

## 2026-01-10 13:03 - Recovery Docs Lint

Normalized recovery and VM docs formatting to satisfy markdownlint. (b8f507d)

## 2026-01-10 12:10 - Audacious Audio Docs Lint

Normalized audacious install docs to satisfy markdownlint formatting. (ee3902c)

## 2026-01-09 01:27 - README Key Subsystems Removal

Dropped the Key Subsystems section to keep the README focused on the docs map.
(c9ae6a2)

## 2026-01-09 01:20 - README Quick Start Cleanup

Removed the Quick Start section to avoid duplicating host install docs.
(b7ec4f1)

## 2026-01-09 01:05 - Audacious Idle Shutdown Behavior

Made idle shutdown immediate after swayidle trigger and cancelable on resume.
Updated docs to match. (19170fe)

## 2026-01-08 01:50 - Astute Netcat Cleanup

Removed netcat-traditional from the Astute base install list after confirming
it is unused in scripts. (5e2f684)

## 2026-01-08 01:52 - Astute Fdisk Cleanup

Removed fdisk from the Astute inventory and base install list. (fb76f50)

## 2026-01-07 20:10 - Off-Site Backup Implementation (Phase 3, Task #9)

Implemented BorgBase off-site repos (audacious-home + astute-critical). Created
root-borg-astute package with systemd units and scripts. Append-only mode for
ransomware protection. Changed astute-critical to weekly schedule (Sunday
15:00). Added health status output to check script. Manual triggers verified
both backups working. (d5eee2f, 6ff1039, ~30+ earlier commits in feature
branch)

## 2026-01-14 16:16 - Format gem PATH drop-in

Aligned shfmt output for the gem PATH bash drop-in. (232d31c)

## 2026-01-14 16:14 - Add gem bin PATH on astute

Add bash drop-in to include user gem executables in PATH. (81d2a9d)

## 2026-01-14 16:12 - Borg offsite test overrides

Added env overrides for borg offsite scripts and updated specs to isolate
missing-key checks. (2507e60)

## 2026-01-14 16:03 - Reload systemd before sshd restart

Added daemon-reload to root-ssh-astute install to avoid reload warning on
restart. (c5ba9f7)

## 2026-01-14 15:55 - Broaden lint coverage

Lint shebang shell scripts, align markdownlint config, and format newly
included scripts. (db41eff)

## 2026-01-14 15:51 - Fix shellspec broken pipe warning

Removed cut pipeline from audio sink selector to avoid broken pipe warnings.
(fce87b0)

## 2026-01-14 15:48 - Suppress SO_PASSCRED noise

Filtered systemd-analyze verify output in unprivileged checks. (2c8ceab)

## 2026-01-14 15:42 - Host-scoped unit verification

Scoped unprivileged systemd unit checks to host packages; updated testing
coverage note. (e38d0b5)

## 2026-01-07 18:30 - Security Audit Complete (Phase 2, Tasks #7-8)

Comprehensive security audit + crypto/SSH key inventory. Overall security
posture: GOOD. All Phase 1 fixes verified operational. Inventoried all SSH keys
(4 pairs → 3 active, deleted unused id_astute_nas). Documented cold storage
procedures. No suspicious activity in logs. Firewall active with 8K+ drops on
Audacious. (d6a1bb4, 2a6993f, 92d8091, fb5122c)

## 2026-01-06 01:50 - Borg Retention Extended

Changed Borg retention from --keep-last 2 to --keep-daily 7 for better recovery
window. Updated documentation. (131df57)

## 2026-01-06 01:45 - Backup Audit + Threat Model (Phase 0, Tasks #3-4)

Completed backup infrastructure audit and threat model. Verified Borg working
(7.15GB → 27.35kB deduplicated). Tested file-level restore successfully.
Documented 3-2-1 backup gap (off-site not yet implemented). Created
comprehensive threat model identifying Medium-High external risk, Medium IoT
lateral movement risk. (cc450c9, 41d5b45, 916a3fb)

## 2026-01-05 23:40 - Userland Principles Audit (Phase 0, Task #2)

Comprehensive audit of Shipshape against four core principles. Key findings:
Principles 3 & 4 (Resilience/Affordability) strongly aligned, Principles 1 & 2
(Autonomy/Security) partially aligned. Critical gaps identified: no firewall,
no threat model, untested recovery. (PRINCIPLES-AUDIT.md created, commit in
earlier session)

────────────────────────────────────────────────────────────────

Session notes older than 2 weeks are removed. See git log for full history: git
log --all --source --full-history -- TODO.md

## 2026-01-08 15:16 - Docs consolidation and naming cleanup

Centralized data restore flow, split secrets recovery/maintenance, normalized
doc filenames/§ headings, and updated drift-check pathing. (917a492, cf98881,
7eabfb3)
