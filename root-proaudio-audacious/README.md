# root-proaudio-audacious

Real-time audio permissions for low-latency audio work.

Grants real-time scheduling privileges to users in the `audio` group, enabling
low-latency audio applications like DAWs, soft synths, and VoIP to run without
dropouts or xruns.

## Contents

### PAM limits configuration

**File**: `etc/security/limits.d/20-audio.conf`

**Settings:**

```text
@audio   -  rtprio     95
@audio   -  memlock    unlimited
```

**What these do:**

- **`rtprio 95`** — Allows audio applications to request
  real-time CPU priority up to level 95 (max is 99)
   - Real-time priority ensures the audio thread runs
     before other processes
   - Prevents audio dropouts caused by CPU contention
   - Level 95 is high enough for audio work but leaves
     headroom for critical system tasks

- **`memlock unlimited`** — Allows unlimited memory
  locking (prevents swapping of audio buffers)
   - Audio buffers must stay in RAM (swapping to disk
     causes xruns)
   - Prevents kernel from paging out audio application
     memory
   - Critical for low-latency audio processing

## When this is needed

**Use cases:**

- **DAW work** (Ardour, Reaper, Bitwig) — Multi-track recording and playback
- **Soft synthesizers** (ZynAddSubFX, sfizz) — Real-time synthesis
- **Audio plugins** (LV2, VST) — Low-latency effects processing
- **VoIP/streaming** (Discord, OBS) — Real-time voice processing
- **Live performance** — JACK audio server with <5ms latency

**Not needed for:**

- Casual music playback (VLC, mpv)
- Web browsers (audio playback is not latency-sensitive)
- Recording with high buffer sizes (>256 samples)

## User setup

The user must be in the `audio` group:

```bash
# Check if user is in audio group
groups | grep audio

# If not, add user to audio group
sudo usermod -aG audio alchemist

# Log out and back in for changes to take effect
```

## Installation

```bash
cd ~/dotfiles
sudo stow -t / root-proaudio-audacious
```

This package uses plain stow (no install script required)
as it contains only a single limits file.

## Verification

After logging out and back in:

```bash
# Check rtprio limit
ulimit -r
# Should output: 95

# Check memlock limit
ulimit -l
# Should output: unlimited
```

## How applications use this

**JACK Audio Connection Kit:**

```bash
# JACK can now run with real-time priority
jackd -R -d alsa -r48000 -p128
# -R flag enables real-time mode (requires rtprio permission)
```

**PipeWire (with WirePlumber):**
PipeWire automatically uses real-time priority if available.
Check with:

```bash
ps -eo pid,cls,rtprio,comm | grep pipewire
# CLS should be RR (real-time round-robin)
# RTPRIO should be non-zero (typically 20-88)
```

**Ardour/DAW:**
DAWs typically have an option in preferences:

- "Use real-time priority" or "Enable RT scheduling"
- This option will only work if these limits are in place

## Troubleshooting

**Application still getting dropouts:**

1. Check audio buffer size (try 256 or 512 samples)
2. Check CPU governor: `cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`
   - Should be `performance` for audio work
   - Use `game-performance` wrapper or
     `powerprofilesctl set performance`
3. Check for CPU throttling: `watch -n1 grep MHz /proc/cpuinfo`
4. Disable CPU power management: See
   `root-power-audacious` for SATA link power management
5. Check PipeWire/JACK logs for xruns

**Permission denied errors:**

- Ensure user is in audio group: `groups`
- Log out and back in after adding to group
- Check limits are active: `ulimit -r` and `ulimit -l`

**System becomes unresponsive:**
If an audio application misbehaves with RT priority, it can
monopolize the CPU:

- Press Ctrl+Alt+F2 to switch to text console
- Log in and kill the process: `killall -9 <app-name>`
- Consider using a lower rtprio value (e.g., 80 instead of 95)

## Security consideration

**Why this is safe:**

- Only users explicitly added to `audio` group have these privileges
- rtprio 95 leaves headroom for kernel tasks (99 is max)
- memlock unlimited is safe on systems with adequate RAM
  (32GB+)

**Why this could be dangerous:**

- A buggy real-time application can freeze the system
- Malicious code running as audio group member could DoS the CPU
- Only add trusted users to the audio group

## See Also

- `pipewire-audacious/` — PipeWire low-latency audio configuration
- `root-cachyos-audacious/etc/udev/rules.d/99-cpu-dma-latency.rules` —
  Allows audio group to control CPU sleep states
- `root-cachyos-audacious/etc/udev/rules.d/40-hpet-permissions.rules` —
  Allows audio group to access high-precision timers
- `/usr/share/doc/ardour/README.Debian` — Ardour-specific real-time setup notes
