# Project Shipshape

Configuration management for "the Wolfpack" — a small ecosystem of independent Linux systems. User-level configs deployed with GNU Stow; system-level configs via install scripts. Designed for clarity, reproducibility, and fast recovery.

---

## What is this?

**Project Shipshape** is the configuration management implementation — this dotfiles repository with everything in order, maintainable, and ready for deployment or disaster recovery.

**The Wolfpack** is the fleet of machines managed by this repository:
- **Audacious** — Main workstation (ZFS root, Sway, development + gaming)
- **Astute** — Low-power NAS/backup server (suspend-on-idle, Wake-on-LAN)
- **Artful** — Cloud instance on Hetzner (currently inactive)
- **Steam Deck** — Portable gaming companion

Hostnames follow Royal Navy submarine names. "Wolfpack" describes the architecture: independent, low-maintenance machines with clearly defined roles that cooperate without tight coupling. Together they form a "workstation × homelab" hybrid with console-like gaming and media capabilities.

All hosts (except Steam Deck) run Debian 13 (Trixie) Stable for excellent ZFS support, predictable behavior, and reduced context switching.

---

## Documentation Map

### Per-Host Guides
Each host has complete rebuild documentation:

**Audacious:**
- [`docs/audacious/install-audacious.md`](docs/audacious/install-audacious.md) — Full installation from scratch
- [`docs/audacious/recovery-audacious.md`](docs/audacious/recovery-audacious.md) — Boot and ZFS recovery
- [`docs/audacious/installed-software-audacious.md`](docs/audacious/installed-software-audacious.md) — Complete package inventory

**Astute:**
- [`docs/astute/install-astute.md`](docs/astute/install-astute.md) — Full installation from scratch
- [`docs/astute/recovery-astute.md`](docs/astute/recovery-astute.md) — Boot and ZFS recovery
- [`docs/astute/installed-software-astute.md`](docs/astute/installed-software-astute.md) — Complete package inventory

### System Reference
- [`docs/hosts-overview.md`](docs/hosts-overview.md) — Hardware specs for all hosts
- [`docs/network-overview.md`](docs/network-overview.md) — Network topology and addressing
- [`docs/threat-model.md`](docs/threat-model.md) — Security threat model and acceptable risks
- [`docs/data-restore.md`](docs/data-restore.md) — Data restore scenarios
- [`docs/secrets-recovery.md`](docs/secrets-recovery.md) — Emergency secrets restore
- [`docs/secrets-maintenance.md`](docs/secrets-maintenance.md) — Secrets USB creation and upkeep
- [`docs/offsite-backup.md`](docs/offsite-backup.md) — Off-site backup design and recovery materials
- [`docs/disaster-recovery.md`](docs/disaster-recovery.md) — Disaster recovery procedures and recovery kit maintenance

---

## Core Principles

These principles guide Project Shipshape and inform decisions across the Wolfpack.

### 1. Autonomy & Control (with Pragmatic Tradeoffs)

The project prioritizes control over core infrastructure while accepting external services where self-hosting isn't viable.

- **Core infrastructure is self-hosted:** Storage, backups, configuration management, and development environment run on owned hardware.
- **External services when justified:** Email, AI, and collaboration tools are externalized when criticality exceeds capability, technical maturity is lacking, or community value outweighs autonomy concerns.
- **Prefer open and portable:** Open standards and auditable software prevent lock-in and enable future migration to self-hosted alternatives.
- **Document the rationale:** Every externalization decision is explicit, justified, and revisited as capabilities evolve.

### 2. Privacy & Security (Defense in Depth)

Security is built on encryption, authentication at trust boundaries, and verifiable software.

- **Authentication at trust boundaries:** External access and cross-host communication require strong authentication; physical security handles single-user workstation access.
- **Encryption for sensitive data:** Sensitive data is encrypted at rest (ZFS, LUKS, Borg) and in transit (SSH, HTTPS); plaintext for non-sensitive traffic (package downloads) is acceptable on the trusted LAN.
- **Auditable software only:** Prefer open-source packages from signed repositories; retain offline recovery paths for all critical data.
- **Threat model guides decisions:** Security posture is explicitly designed for home lab threats, not enterprise or nation-state targeting.

### 3. Resilience & Portability

The project prioritizes recoverability and avoids lock-in to enable fast recovery and long-term sustainability.

- **Recovery is paramount:** Multiple backup tiers (local, off-site, offline), documented procedures, and tested restore paths ensure rapid recovery from any disaster scenario.
- **Minimal lock-in:** Open standards (git, SSH, Borg, NFS) and portable data formats allow components to be swapped or migrated without architectural changes.
- **Documentation-driven rebuilds:** Complete installation and recovery documentation enables rebuilds without specialist knowledge or vendor support.
- **Version control:** All configs, scripts, and documentation are versioned to enable point-in-time recovery and audit trails.

### 4. Affordability and Broad Accessibility

The stack is designed to remain sustainable for users with modest means and common hardware.

- **Modest recurring costs:** Domains, VPS, and storage kept affordable, excluding ISP costs and already-owned hardware.
- **Prefer FOSS alternatives:** Paid external services are treated as replaceable by self-hosted or open-source alternatives where viable.
- **Hardware flexibility:** The stack must remain usable on older hardware, including low-RAM systems and spinning disks; enterprise features are helpful but not required.

---

## Implementation Patterns

How these principles translate into practice:

### Configuration Management
- **Plain text configuration:** Everything versioned, transparent, and understandable
- **Standard Debian packages:** No Snaps, AppImages, or Flatpaks
- **Direct tooling:** GNU Stow and systemd, without config management abstraction layers
- **Explicit over clever:** Clear scripts and dependencies over abstraction

### Per-Host Isolation
- **Independent recovery:** Each machine can be rebuilt from its own packages
- **Minimal shared files:** `profile-common` and `bin-common` are the only shared configs; they don't create deployment dependencies between hosts
- **Package inventory tracking:** Installed software lists and drift-check scripts track divergence from base Debian

---

## Pragmatic Exceptions

Project Shipshape balances principled self-hosting with practical constraints. External services are acceptable when: (1) criticality exceeds capability, (2) self-hosted alternatives are immature, (3) community integration provides significant value, or (4) self-hosting cost outweighs benefit—provided migration paths remain viable.

### Self-Hosted Services
- Configuration management, NAS/file storage, encrypted backups, APT caching, development environment

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
