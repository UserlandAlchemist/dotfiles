PROJECT SHIPSHAPE - WORK QUEUE
======================================
Updated: 2026-01-08 00:49

Project Shipshape: Dotfiles and configuration management for the Wolfpack.
The Wolfpack: Audacious (workstation), Astute (NAS/server), Artful (cloud), Steam Deck (portable).

Work queue and session notes for project planning and progress tracking.

────────────────────────────────────────────────────────────────
EXECUTION ORDER (Start Here - Dependency Ordered)
────────────────────────────────────────────────────────────────

Follow this sequence for optimal progress. Tasks are dependency-ordered.
Strike through completed items and move to next.

PHASE 0 - Philosophy & Validation (Week 1-2):
  1. [x] ~~USERLAND ARCHIVE IMPORT - Review philosophy FIRST (shapes all decisions)~~ (docs/principles.md: 5a9f8b6, 604eac1)
  2. [x] ~~USERLAND PRINCIPLES AUDIT - Audit Shipshape against principles (depends on #1)~~ (docs/PRINCIPLES-AUDIT.md: comprehensive review)
  3. [x] ~~BACKUP AUDIT + RESTORE TESTS - Validate core assumption (can run parallel with #2)~~ (docs/BACKUP-AUDIT.md: cc450c9)
  4. [x] ~~DEVELOP THREAT MODEL - Define security assumptions (depends on: #2 principles audit)~~ (docs/threat-model.md)

PHASE 1 - Critical Security Fixes (URGENT - 2026-01-06):
  5. [x] ~~SSH HARDENING (ASTUTE) - Lock SSH to LAN IP (P0-Critical, security audit finding)~~
  6. [x] ~~HOST FIREWALL IMPLEMENTATION - nftables on both hosts (P0-Critical, escalated from P1-High)~~

PHASE 2 - Security Audit (After Critical Fixes):
  7. [x] ~~COMPLETE SECURITY AUDIT - Full audit of services, configs, auth policies (depends on: Phase 1 complete)~~ (docs/security-audit.md)
  8. [x] ~~CRYPTO AUDIT - SSH/GPG key inventory and cleanup (runs alongside #7)~~ (included in security-audit.md)

PHASE 3 - Critical Backups & Infrastructure (Week 2-3):
  9. [x] ~~OFF-SITE BACKUP IMPLEMENTATION - BorgBase repositories (P1-High, critical data protection)~~ (commits: 27a4e7c, 623a4c9, 827210e, 5a50238)
  10. [x] ~~INSTALL LIBRARY - Idempotent scripts (depends on: Userland philosophy)~~ (commits: c135f32, 711e0ed, f36a5a6, 35a89c6)
  11. [ ] VM TESTING ENVIRONMENT - Safe testing ground (no dependencies)

PHASE 4 - Documentation & Validation (Week 3-4):
  12. [ ] UPDATE STRATEGY - Document safe updates (depends on: Userland philosophy)
  13. [ ] DISASTER RECOVERY DRILL - Validate docs (depends on: VM environment, backup tests)

PHASE 5 - Protection & Monitoring (Week 4-5):
  14. [ ] MONITORING & ALERTING - Early warning system (depends on: Userland philosophy, threat model)
  15. [ ] VPN + ENCRYPTED DNS SETUP - Privacy protection (P1-High, UK surveillance concerns)

PHASE 6 - Quality of Life (Ongoing, as needed):
  16. [ ] TORRENTING TO ASTUTE - Offload workstation, better suspend
  17. [ ] PASSWORD MANAGER REVIEW - Evaluate self-hosting options (Vaultwarden, alternatives)
  18. [ ] MPD + TAGGING WORKFLOW AUDIT - Music library management
  19. [ ] PROJECT INTEGRAL DOCUMENTATION - DAW context

SCHEDULED (Post 2026-01-12):
  20. [ ] REMOVE CLAUDE TOOLING - Transition to Codex-only workflow

DEFERRED (Prerequisites required):
  21. [ ] ARTFUL SECURITY HARDENING - Prerequisites for VPS deployment (P1-High, blocks Artful activation)

────────────────────────────────────────────────────────────────
RECENT SESSION NOTES
────────────────────────────────────────────────────────────────

## 2026-01-08 00:49 - Documentation Consolidation
Comprehensive audit of all documentation. Fixed terminology inconsistencies (6 "blue USB" → "Secrets USB"). Eliminated 659 lines (23.6%) of duplication and low-value content. Deleted key-inventory.md (296 lines, content duplicated elsewhere). Removed implementation tasks from threat-model.md (161 lines). Removed generic best practices from secrets-recovery.md (72 lines). Changed 9 docs from 600 to 644 permissions. (08c2e89, b72ad04)

## 2026-01-08 00:15 - Agent Coordination File Cleanup
Condensed TODO.md from 2046 to 85 lines (96% reduction). Streamlined AGENTS.md from 228 to 119 lines. Updated ~/.claude/CLAUDE.md to match new condensed session notes approach. Session notes now 2-3 lines with commit hashes; detailed work lives in git. (e700360)

## 2026-01-07 23:30 - Install Library (Phase 3, Task #10)
Created lib/install.sh with 9 reusable functions, refactored all 13 root-* install scripts, eliminated 114 lines (-38% avg). Added 30s timeout to daemon-reload. Created regression test suite - all 13 packages passed. (c135f32, 711e0ed, f36a5a6, 35a89c6, f1d943c)

## 2026-01-07 22:00 - Disaster Recovery Infrastructure
Fixed Secrets USB missing BorgBase credentials. Created three-tier recovery strategy (Secrets USB + Trusted Copy + Google Drive) with SHA256 verification. Renamed "Blue USB" → "Secrets USB" throughout. Created verify/clone/bundle scripts. Audited both hosts for leftover secrets (all clean). Enhanced .gitignore protection. (5d560cd, 4da5fa6, 8938021, 6e399dc, da71619, 6a27cf5, 90b1495, 703fd50, 34978d5)

## 2026-01-08 01:13 - Documentation Alignment + Drift Check
Refocused threat model as timeless design doc and trimmed security audit to an operational log. Removed duplicated overview/offsite documentation. Updated drift checker to ignore non-APT installs and refreshed Audacious software list (GTK theme tools); drift check clean. (8b82c4d, dd5fd62, 44ed3e3)

## 2026-01-08 01:17 - Astute Drift Check
Confirmed jellyfin-ffmpeg7 and zfs-zed are installed on Astute, removed nfs-common from inventory, and refreshed drift-check date. (ec48d44)

## 2026-01-08 01:25 - Drift Check Script Shared
Moved check-drift.sh into bin-common with host-aware behavior and updated docs to reference the shared tool. (3e7449a)

## 2026-01-08 01:28 - Drift Check Script Fix
Hardened check-drift.sh to tolerate empty local-deb matches. (12a3528)

## 2026-01-08 01:29 - Astute Drift Check Refinement
Adjusted Astute drift checks to compare against all installed packages using dpkg-query. (28817ce)

## 2026-01-08 01:35 - Drift Check Unification
Switched check-drift.sh back to apt-mark showmanual for all hosts after normalizing Astute manual marks. (0637292)

## 2026-01-08 01:38 - Astute Firmware Inventory
Recorded intel-microcode and firmware-amd-graphics in the Astute software list after marking them manual. (fdf9667)

## 2026-01-08 01:39 - Astute Manual Package Tracking
Added nano, nftables, and tasksel meta packages to the Astute software inventory after marking them manual. (51aaa91)

## 2026-01-08 01:41 - Astute Install List Update
Added nano, nftables, firmware/microcode, and tasksel meta packages to the Astute base install list; removed nfs-common. (778039c)

## 2026-01-08 01:42 - Astute Utility Additions
Added fdisk, dhcpcd-base, and usbutils to the Astute inventory and install list after marking them manual. (f25a215)

## 2026-01-08 01:44 - Astute Tasksel Cleanup
Removed task-english from the Astute inventory and install list after marking it auto. (3a125ce)

## 2026-01-08 01:50 - Astute Netcat Cleanup
Removed netcat-traditional from the Astute base install list after confirming it is unused in scripts. (5e2f684)

## 2026-01-08 01:52 - Astute Fdisk Cleanup
Removed fdisk from the Astute inventory and base install list. (fb76f50)

## 2026-01-07 20:10 - Off-Site Backup Implementation (Phase 3, Task #9)
Implemented BorgBase off-site repos (audacious-home + astute-critical). Created root-offsite-astute package with systemd units and scripts. Append-only mode for ransomware protection. Changed astute-critical to weekly schedule (Sunday 15:00). Added health status output to check script. Manual triggers verified both backups working. (d5eee2f, 6ff1039, ~30+ earlier commits in feature branch)

## 2026-01-07 18:30 - Security Audit Complete (Phase 2, Tasks #7-8)
Comprehensive security audit + crypto/SSH key inventory. Overall security posture: GOOD. All Phase 1 fixes verified operational. Inventoried all SSH keys (4 pairs → 3 active, deleted unused id_astute_nas). Documented cold storage procedures. No suspicious activity in logs. Firewall active with 8K+ drops on Audacious. (d6a1bb4, 2a6993f, 92d8091, fb5122c)

## 2026-01-06 01:50 - Borg Retention Extended
Changed Borg retention from --keep-last 2 to --keep-daily 7 for better recovery window. Updated documentation. (131df57)

## 2026-01-06 01:45 - Backup Audit + Threat Model (Phase 0, Tasks #3-4)
Completed backup infrastructure audit and threat model. Verified Borg working (7.15GB → 27.35kB deduplicated). Tested file-level restore successfully. Documented 3-2-1 backup gap (off-site not yet implemented). Created comprehensive threat model identifying Medium-High external risk, Medium IoT lateral movement risk. (cc450c9, 41d5b45, 916a3fb)

## 2026-01-05 23:40 - Userland Principles Audit (Phase 0, Task #2)
Comprehensive audit of Shipshape against four core principles. Key findings: Principles 3 & 4 (Resilience/Affordability) strongly aligned, Principles 1 & 2 (Autonomy/Security) partially aligned. Critical gaps identified: no firewall, no threat model, untested recovery. (PRINCIPLES-AUDIT.md created, commit in earlier session)

────────────────────────────────────────────────────────────────

Session notes older than 2 weeks are removed. See git log for full history:
  git log --all --source --full-history -- TODO.md
## 2026-01-08 15:16 - Docs consolidation and naming cleanup
Centralized data restore flow, split secrets recovery/maintenance, normalized doc filenames/§ headings, and updated drift-check pathing. (917a492, cf98881, 7eabfb3)
