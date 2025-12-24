# APT Proxy Failover Implementation - Engineering Decisions

**Status:** Ready for implementation by Codex
**Assigned to:** Codex
**Reviewed by:** Claude Sonnet 4.5
**Date:** 2025-12-24

---

## Problem Statement

Current `/etc/apt/apt.conf.d/01proxy` hardcodes:
```
Acquire::http::Proxy "http://192.168.1.154:3142";
```

When astute is down/sleeping, apt operations hang or fail.

---

## Architectural Decision (Claude)

**Solution:** Use apt's built-in `Acquire::http::ProxyAutoDetect` mechanism.

**Rationale:**
- Native apt feature, no custom systemd complexity
- Runs on-demand (only when apt needs it)
- Fast failover (1-2 second detection)
- Simple, auditable, minimal moving parts

**Rejected alternatives:**
- Systemd service to rewrite config file (too complex, racy)
- NetworkManager hooks (overkill, unnecessary dependency)
- Static timeout in apt (still blocks, poor UX)

---

## Implementation Specification

### 1. Detection Script

**Location:** `/usr/local/bin/apt-proxy-detect.sh`

**Purpose:** Quickly determine if apt-cacher-ng on astute is reachable

**Logic:**
```bash
#!/bin/bash
# Fast proxy detection for apt-cacher-ng on astute

PROXY_HOST="192.168.1.154"
PROXY_PORT="3142"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"

# Quick ping check (1 second timeout)
if ping -c1 -W1 "$PROXY_HOST" >/dev/null 2>&1; then
    echo "$PROXY_URL"
else
    echo "DIRECT"
fi
```

**Requirements:**
- Executable: `chmod 755`
- Must be fast (<2 seconds worst case)
- No dependencies beyond coreutils
- Output ONLY the proxy URL or "DIRECT"

**Error handling:**
- On any error/timeout: return "DIRECT" (safe fallback)
- No stderr output (apt expects clean stdout)

---

### 2. APT Configuration

**Location:** `/etc/apt/apt.conf.d/01proxy`

**New content:**
```
Acquire::http::ProxyAutoDetect "/usr/local/bin/apt-proxy-detect.sh";
Acquire::https::Proxy "false";
```

**Explanation:**
- ProxyAutoDetect calls the script before each apt operation
- https proxy disabled (apt-cacher-ng doesn't cache HTTPS)
- Simple, declarative config

---

### 3. Stow Package Structure

**Package name:** `root-network-audacious`

**Rationale:** Host-specific (references astute's IP address)

**Structure:**
```
root-network-audacious/
├── etc/
│   └── apt/
│       └── apt.conf.d/
│           └── 01proxy
├── usr/
│   └── local/
│       └── bin/
│           └── apt-proxy-detect.sh
└── install.sh
```

**install.sh responsibilities:**
1. Check if running as root
2. Stow the package: `stow -t / root-network-audacious`
3. Set executable permission: `chmod 755 /usr/local/bin/apt-proxy-detect.sh`
4. Test the setup: run apt-proxy-detect.sh and verify output

---

## Testing Plan

### Test 1: Astute reachable
```bash
# Wake astute
ssh-astute exit

# Test detection script
/usr/local/bin/apt-proxy-detect.sh
# Expected output: http://192.168.1.154:3142

# Test apt uses proxy
sudo apt update
# Should complete quickly, using proxy
```

### Test 2: Astute unreachable
```bash
# Put astute to sleep or disconnect network
nas-close

# Test detection script
/usr/local/bin/apt-proxy-detect.sh
# Expected output: DIRECT

# Test apt bypasses proxy
sudo apt update
# Should complete normally, direct to mirrors
```

### Test 3: Failover during operation
```bash
# Start with astute up, verify proxy works
# Put astute to sleep mid-operation
# Next apt command should auto-failover to DIRECT
```

---

## Documentation Updates

### 1. INSTALL.audacious.md

Add to network section (after NFS setup):

```markdown
### APT Proxy (apt-cacher-ng)

Audacious uses apt-cacher-ng running on Astute to cache package downloads,
reducing bandwidth and speeding up repeated installations.

The proxy configuration includes automatic failover - if Astute is unreachable,
apt falls back to direct downloads from Debian mirrors.

**Setup:**

1. Deploy proxy configuration:
   ```bash
   cd ~/dotfiles
   sudo ./root-network-audacious/install.sh
   ```

2. Test detection:
   ```bash
   /usr/local/bin/apt-proxy-detect.sh
   # Returns: http://192.168.1.154:3142 (if astute up)
   # Returns: DIRECT (if astute down)
   ```

3. Verify failover:
   ```bash
   sudo apt update  # Should work whether astute is up or down
   ```

**How it works:**
- apt calls `/usr/local/bin/apt-proxy-detect.sh` before each operation
- Script checks if astute:3142 is reachable (1s timeout)
- Returns proxy URL if available, "DIRECT" otherwise
- Zero-config failover, no manual intervention needed
```

### 2. docs/network-overview.md

Add section on apt proxy architecture:

```markdown
## APT Proxy (apt-cacher-ng)

**Service:** apt-cacher-ng on astute:3142
**Clients:** audacious (automatic failover)

**Architecture:**
- Astute runs apt-cacher-ng to cache Debian packages
- Audacious uses `Acquire::http::ProxyAutoDetect` for smart proxy selection
- Detection script checks astute reachability (ping, 1s timeout)
- Automatic fallback to DIRECT if astute unavailable

**Benefits:**
- Reduced bandwidth (packages cached after first download)
- Faster installations (LAN speed vs internet)
- Works offline for cached packages
- Zero-config failover (no manual intervention)

**Configuration:**
- `/etc/apt/apt.conf.d/01proxy` - ProxyAutoDetect configuration
- `/usr/local/bin/apt-proxy-detect.sh` - Reachability detection script
- Managed via stow: `root-network-audacious` package
```

---

## Implementation Checklist for Codex

- [x] Create `root-network-audacious/` directory structure
- [x] Write `apt-proxy-detect` script with exact logic above
- [x] Create `01proxy` config with ProxyAutoDetect
- [x] Write `install.sh` with permission setup and testing
- [ ] Test script manually (astute up and down)
- [ ] Run install.sh and verify stow deployment
- [ ] Test apt update with astute up
- [ ] Test apt update with astute down
- [x] Update INSTALL.audacious.md network section
- [x] Update docs/network-overview.md
- [ ] Add installed software entry (if any new packages needed)
- [ ] Commit all changes with clear message
- [x] Update AGENTS-TODO.txt with completion status

---

## Critical Notes

1. **Script must be fast:** 1-2 second maximum execution time
2. **Safe fallback:** On ANY error, return "DIRECT"
3. **No stderr output:** apt expects clean stdout
4. **Test thoroughly:** Verify both proxy and direct modes work
5. **Host-specific:** Only for audacious (astute IP hardcoded)

---

## Questions / Clarifications

If unclear during implementation:
1. Check existing network-overview.md for astute IP confirmation
2. Test with `sudo apt update` not `apt install` (safer)
3. Don't modify anything outside root-network-audacious package
4. If issues, document in handoff and wait for Claude

---

**Engineering decision made by:** Claude Sonnet 4.5
**Implementation assigned to:** Codex
**Expected completion:** Next Codex session
