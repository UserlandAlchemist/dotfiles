# Principles

These principles guide Project Shipshape and inform decisions across the
Wolfpack.

---

# Self-Hosted by Design

This project is designed as a fully self-hosted digital ecosystem—spanning the
desktop, home server, VPS, off-site storage, and mobile devices—so essential
services (email, file sync, media streaming, secrets management, and on-prem AI)
run on hardware and software under direct control.

It covers software selection, service orchestration, code-driven provisioning,
automated snapshots and backups, secure remote access, phased migration,
continual experimentation, and an ethos of “giving back.” The work is guided by
four core principles:

## 1. Autonomy & Freedom (with Pragmatic Constraints)

The project reclaims control over the digital stack—choosing every component—
while balancing real-world costs and ongoing effort.

- Essential services are self-hosted on owned hardware and software.
- Open, auditable software is preferred; exceptions are rare and justified.
- Architectural and tooling choices are weighed against cost, time, and
  maintenance impact to keep the setup sustainable.

## 2. Privacy & Security as a Foundation (Trust by Verification)

Security is built on verification, and privacy is treated as non-negotiable.

- Every access requires authentication and authorization, inside or outside the
  network.
- Sensitive data is encrypted in transit and at rest to guard against leaks.
- Only auditable software is run, and offline recovery paths (keys, snapshots)
  are retained under direct control.

## 3. Agile Learning & Resilience

The project encourages learning by doing, rapid experimentation, and fast
recovery—without becoming a full-time sysadmin.

- Services are treated as disposable: easy to spin up, swap, or tear down, with
  scoped rollbacks.
- The entire stack—configs, code, snapshots, backups—is versioned to enable
  rebuilds and sharing.
- Open standards and isolated segments allow components to be swapped cleanly
  and issues contained.

## 4. Affordability and Broad Accessibility

The stack is designed to remain sustainable for users with modest means and
common hardware.

- Recurring costs (domains, VPS, storage) are kept modest, excluding ISP costs
  and already-owned hardware.
- Paid external services are treated as replaceable by self-hosted or FOSS
  alternatives where viable.
- The stack must remain usable on older hardware, including low-RAM systems and
  spinning disks; enterprise features are helpful but not required.

---

This document serves as a compass for technical and architectural choices,
grounding each step in a coherent, sustainable philosophy of digital
self-determination.
