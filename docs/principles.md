# Principles

These principles guide Project Shipshape and inform decisions across the
Wolfpack.

---

# Self-Hosted by Design

I’m designing and building a fully self-hosted digital ecosystem—spanning my
desktop, home server, VPS, off-site storage, and mobile devices—that means I run
all of my essential services (email, file sync, media streaming, secrets
management, and on-prem AI) on hardware and software I control.

This project covers software selection, service orchestration, code-driven
provisioning, automated snapshots and backups, secure remote access, phased
migration, continual experimentation, and an ethos of “giving back” wherever
possible. To stay focused and make consistent decisions, I’m guided by four core
principles:

## 1. Autonomy & Freedom (with Pragmatic Constraints)

I reclaim full control over my digital life—choosing every component I run—while
balancing real-world costs and ongoing effort.

- I host my own services (email, file sync, media, secrets, AI) on hardware and
  software I control.
- I favor open, auditable software, making exceptions only when absolutely
  necessary.
- I weigh each architectural or tooling choice against its monetary, time, and
  maintenance impact to keep my setup sustainable.

## 2. Privacy & Security as a Foundation (Trust by Verification)

I build security on verifying every interaction, and I treat privacy as
non-negotiable.

- I require authentication and authorization for every access, whether inside
  or outside my network.
- I encrypt all sensitive data in transit and at rest to guard against
  eavesdropping or data leaks.
- I run only software I can audit, and I maintain offline recovery paths (keys,
  snapshots) that only I control.

## 3. Agile Learning & Resilience

I learn by doing, experiment fearlessly, and bounce back instantly when things
break—without becoming a full-time sysadmin.

- I treat each service as disposable: I spin it up, swap it, or tear it down in
  minutes, and roll back only the part that fails.
- I capture my entire stack—configurations, code, snapshots, and backups—in
  versioned form so I can rebuild, share, or improve it at will.
- I build atop open standards and isolated segments so I can swap components
  seamlessly and contain any issues.

## 4. Affordability and Broad Accessibility

I design this stack to be sustainable for anyone with modest means and access to
common consumer hardware.

- I aim to keep total recurring costs (e.g. domains, VPS, storage) modest
  (currently under $15/month, excluding normal ISP costs and hardware already
  owned)
- I treat every outside fee—cloud storage, email hosting, VPNs, paid AI
  tools—as replaceable by self-hosted or FOSS alternatives where viable.
- The stack must remain usable on older hardware—including older, reused low-RAM
  systems and spinning disks. Enterprise features (like NAS-class drives) are
  beneficial, but never required.

---

This document serves as my compass for technical and architectural choices,
grounding each step in a coherent, sustainable philosophy of digital
self-determination.
