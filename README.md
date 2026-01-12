# Project Shipshape

Configuration management for "the Wolfpack" - a small ecosystem of independent
Linux systems. User-level configs deployed with GNU Stow; system-level configs
via install scripts. Designed for clarity, reproducibility, and fast recovery.

---

## Project Overview

**Project Shipshape** — This dotfiles repository managing the Wolfpack.

**The Wolfpack** is the fleet of machines managed by this repository:

- **Audacious** — Main workstation (ZFS root, Sway, development + gaming)
- **Astute** — Low-power NAS/backup server (suspend-on-idle, Wake-on-LAN)
- **Artful** — Cloud instance on Hetzner (currently inactive)
- **Steam Deck** — Portable gaming companion

Hostnames follow Royal Navy submarine names. "Wolfpack" describes independent,
low-maintenance machines that cooperate without tight coupling. Together they
form a "workstation x homelab" hybrid with console-like gaming and media
capabilities.

All hosts (except Steam Deck) run Debian 13 (Trixie) Stable for excellent ZFS
support, predictable behavior, and reduced context switching.

---

## Documentation Map

### Per-Host Guides

Each host has complete rebuild documentation:

**Audacious:**

- [Audacious install][audacious-install] - Full installation from scratch
- [Audacious recovery][audacious-recovery] - Boot and ZFS recovery
- [Audacious software inventory][audacious-software] - Complete package inventory

**Astute:**

- [Astute install][astute-install] - Full installation from scratch
- [Astute recovery][astute-recovery] - Boot and ZFS recovery
- [Astute software inventory][astute-software] - Complete package inventory

### System Reference

- [`docs/infrastructure.md`](docs/infrastructure.md) - Network and hardware
  reference
- [`docs/threat-model.md`](docs/threat-model.md) - Security threat model and
  acceptable risks
- [`docs/disaster-recovery.md`](docs/disaster-recovery.md) - Disaster scenarios
  and recovery procedures
- [`docs/recovery-kit-maintenance.md`](docs/recovery-kit-maintenance.md) -
  Recovery kit creation and maintenance
- [`docs/offsite-backup.md`](docs/offsite-backup.md) - BorgBase setup and
  operations

[audacious-install]: docs/audacious/install-audacious.md
[audacious-recovery]: docs/audacious/recovery-audacious.md
[audacious-software]: docs/audacious/installed-software-audacious.md
[astute-install]: docs/astute/install-astute.md
[astute-recovery]: docs/astute/recovery-astute.md
[astute-software]: docs/astute/installed-software-astute.md

---

## Core Principles

### 1. Autonomy & Control (with Pragmatic Tradeoffs)

Prioritizes control over core infrastructure while accepting external services
where self-hosting isn't viable.

- **Core infrastructure is self-hosted:** Storage, backups, configuration
  management, and development environment run on owned hardware.
- **External services when justified:** Email, AI, and collaboration tools are
  externalized when criticality exceeds capability, technical maturity is
  lacking, or community value outweighs autonomy concerns.
- **Prefer open and portable:** Open standards and auditable software prevent
  lock-in and enable future migration to self-hosted alternatives.
- **Document the rationale:** Every externalization decision is explicit,
  justified, and revisited as capabilities evolve.

### 2. Privacy & Security (Defense in Depth)

Security is built on encryption, authentication at trust boundaries, and
verifiable software.

- **Authentication at trust boundaries:** External access and cross-host
  communication require strong authentication; physical security handles
  single-user workstation access.
- **Encryption for sensitive data:** Sensitive data is encrypted at rest (ZFS,
  LUKS, Borg) and in transit (SSH, HTTPS); plaintext for non-sensitive traffic
  (package downloads) is acceptable on the trusted LAN.
- **Auditable software only:** Prefer open-source packages from signed
  repositories; retain offline recovery paths for all critical data.
- **Threat model guides decisions:** Security posture is explicitly designed
  for home lab threats, not enterprise or nation-state targeting.

### 3. Resilience & Portability

Prioritizes recoverability and avoids lock-in for fast recovery and long-term
sustainability.

- **Recovery is paramount:** Multiple backup tiers (local, off-site, offline),
  documented procedures, and tested restore paths ensure rapid recovery from any
  disaster scenario.
- **Minimal lock-in:** Open standards (git, SSH, Borg, NFS) and portable data
  formats allow components to be swapped or migrated without architectural
  changes.
- **Documentation-driven rebuilds:** Complete installation and recovery
  documentation enables rebuilds without specialist knowledge or vendor support.
- **Version control:** All configs, scripts, and documentation are versioned to
  enable point-in-time recovery and audit trails.

### 4. Affordability and Broad Accessibility

The stack is designed to remain sustainable for users with modest means and
common hardware.

- **Modest recurring costs:** Domains, VPS, and storage kept affordable,
  excluding ISP costs and already-owned hardware.
- **Prefer FOSS alternatives:** Paid external services are treated as
  replaceable by self-hosted or open-source alternatives where viable.
- **Hardware flexibility:** The stack must remain usable on older hardware,
  including low-RAM systems and spinning disks; enterprise features are helpful
  but not required.

---

## Implementation Patterns

### Configuration Management

- **Plain text configuration:** Everything versioned, transparent, and
  understandable
- **Standard Debian packages:** No Snaps, AppImages, or Flatpaks
- **Direct tooling:** GNU Stow and systemd, without config management
  abstraction layers
- **Explicit over clever:** Clear scripts and dependencies over abstraction

### Per-Host Isolation

- **Independent recovery:** Each machine can be rebuilt from its own packages
- **Minimal shared files:** `profile-common` and `bin-common` are the only shared
  configs; they don't create deployment dependencies between hosts
- **Package inventory tracking:** Installed software lists and drift-check
  scripts track divergence from base Debian

---

## Testing and Validation

- Run `./scripts/test-dotfiles.sh` after config changes
- Run `sudo ./scripts/test-dotfiles-privileged.sh` after install or systemd edits
- See [`docs/testing.md`](docs/testing.md) for full coverage and guidance

---

## Pragmatic Exceptions

Balances principled self-hosting with practical constraints. External services
are acceptable when: (1) criticality exceeds capability, (2) self-hosted
alternatives are immature, (3) community integration provides significant
value, or (4) self-hosting cost outweighs benefit, provided migration paths
remain viable.

### Self-Hosted Services

- Configuration management, NAS/file storage, encrypted backups, APT caching,
  development environment

### External Services

- **AI:** ChatGPT Plus (AMD GPU/driver immaturity for local LLM)
- **Email:** External provider (criticality exceeds current capability)
- **Code Hosting:** GitHub (community integration value, git portability)
- **Password Management:** Bitwarden (evaluating Vaultwarden migration)
- **DNS:** Cloudflare (minimal lock-in, portable)

---

## License

All original configuration, scripts, and documentation © Userland Alchemist.
Shared under the **MIT License** unless otherwise noted.

---
