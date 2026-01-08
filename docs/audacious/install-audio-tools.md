# Audio Tools Installation Guide

Manual installation procedures for pro audio software not available in Debian repositories.

**Target system:** Audacious
**Scope:** /opt and /usr/local installations of sfizz, ZynAddSubFX Fusion, and VCV Rack

---

## Overview

These audio tools are intentionally installed outside Debian package management:
- **sfizz** — SFZ sample-based synthesizer (LV2 plugin)
- **ZynAddSubFX Fusion** — Advanced software synthesizer with modern UI
- **VCV Rack** — Virtual modular synthesizer (Eurorack simulator)

**Why not in Debian repos:**
- Not packaged for Debian Trixie
- Require specific versions for compatibility with pro audio workflow
- Updates managed manually to avoid breaking project compatibility

**Installation locations:**
- sfizz → `/usr/local/lib/lv2/sfizz.lv2` and `/usr/local/lib/libsfizz*`
- ZynAddSubFX Fusion → `/opt/zyn-fusion`
- VCV Rack → `/opt/vcv-rack/rack-{version}`

---

## Prerequisites

Steps:
1. Install build dependencies and audio framework:

```sh
sudo apt update
sudo apt install -y build-essential git cmake pkg-config \
  libjack-jackd2-dev liblo-dev libasound2-dev \
  lv2-dev libgl1-mesa-dev libfontconfig1-dev \
  libcairo2-dev libfftw3-dev libmxml-dev \
  libtool automake bison ruby python3
```

2. Ensure PipeWire/JACK bridge is configured:

```sh
systemctl --user status pipewire-pulse.service
systemctl --user status pipewire-jack.service
```

Both should be active (configured by `pipewire-audacious/` dotfiles package).

Expected result: Build environment ready for audio software compilation.

---

## §1 Install sfizz (SFZ sampler)

sfizz is an LV2/VST3 plugin for playing SFZ sample instruments. Used in Ardour and other DAWs.

### §1.1 Download sfizz

Official repository: [sfztools/sfizz on GitHub](https://github.com/sfztools/sfizz)

Steps:
1. Check latest release:

Visit: https://github.com/sfztools/sfizz/releases

Look for latest stable release (e.g., 1.2.3).

2. Download source tarball:

```sh
cd ~/Downloads
wget https://github.com/sfztools/sfizz/releases/download/1.2.3/sfizz-1.2.3.tar.gz
tar xzf sfizz-1.2.3.tar.gz
cd sfizz-1.2.3
```

**Replace version number** with current release.

Expected result: Source code extracted and ready to build.

---

### §1.2 Build and install sfizz

Steps:
1. Create build directory:

```sh
mkdir build
cd build
```

2. Configure with CMake:

```sh
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DSFIZZ_LV2=ON \
      -DSFIZZ_VST3=ON \
      -DSFIZZ_LV2_UI=ON \
      ..
```

**Options:**
- `CMAKE_INSTALL_PREFIX=/usr/local` — Install to /usr/local (not /opt)
- `SFIZZ_LV2=ON` — Build LV2 plugin
- `SFIZZ_VST3=ON` — Build VST3 plugin
- `SFIZZ_LV2_UI=ON` — Build LV2 UI

3. Build:

```sh
make -j$(nproc)
```

4. Install (requires sudo):

```sh
sudo make install
```

5. Verify installation:

```sh
ls -l /usr/local/lib/lv2/sfizz.lv2
ls -l /usr/local/lib/libsfizz*
```

Should see `sfizz.lv2/` directory and `libsfizz.so*` files.

6. Update LV2 cache:

```sh
lv2ls | grep sfizz
```

Should output: `http://sfztools.github.io/sfizz`

7. Clean up build directory:

```sh
cd ~/Downloads
rm -rf sfizz-1.2.3*
```

Expected result: sfizz LV2 plugin available in Ardour and other LV2 hosts.

---

### §1.3 Document installation

Record version and date for future reference:

```sh
cat > ~/dotfiles/docs/audacious/INSTALLED-AUDIO-VERSIONS.txt <<EOF
sfizz $(ls /usr/local/lib/libsfizz.so.* | grep -oP '\d+\.\d+\.\d+')
Installed: $(date +%Y-%m-%d)
Source: https://github.com/sfztools/sfizz/releases
Location: /usr/local/lib/lv2/sfizz.lv2
EOF
```

---

## §2 Install ZynAddSubFX Fusion

ZynAddSubFX is an advanced software synthesizer. Fusion is the modern UI version (3.0+).

### §2.1 Download Zyn-Fusion

Official download: [zynaddsubfx.sourceforge.io/download.html](https://zynaddsubfx.sourceforge.io/download.html)

**Options:**
- **Demo version** — Free, fully functional with nag screen
- **Full version** — $45+ USD, no nag screen

Steps:
1. Download from official site:

Visit: https://zynaddsubfx.sourceforge.io/download.html

Download: "Linux Zyn-Fusion VST+LV2+Standalone Binaries" (Demo or Full)

2. Extract tarball:

```sh
cd ~/Downloads
tar xjf zyn-fusion-linux-*-demo-*.tar.bz2
cd zyn-fusion-linux-*-demo-*
```

3. Review contents:

```sh
ls -la
```

Should see: `install-linux.sh`, `zynaddsubfx`, `ZynAddSubFX.lv2/`, `banks/`, etc.

Expected result: Pre-built Zyn-Fusion binaries extracted.

---

### §2.2 Install Zyn-Fusion

Steps:
1. Run installation script as root:

```sh
sudo ./install-linux.sh
```

**What it does:**
- Copies binaries to `/opt/zyn-fusion`
- Installs LV2 plugin to `/usr/local/lib/lv2/ZynAddSubFX.lv2`
- Creates desktop entry

2. Verify installation:

```sh
ls -l /opt/zyn-fusion/
ls -l /usr/local/lib/lv2/ZynAddSubFX.lv2
```

3. Test standalone:

```sh
/opt/zyn-fusion/zynaddsubfx
```

Should launch Zyn-Fusion UI.

4. Test LV2 plugin in Ardour:
   - Launch Ardour
   - Add instrument track
   - Search for "ZynAddSubFX"
   - Load plugin

5. Create version record:

```sh
cat /opt/zyn-fusion/VERSION
```

Record version number.

6. Clean up:

```sh
cd ~/Downloads
rm -rf zyn-fusion-linux-*
```

Expected result: Zyn-Fusion available as standalone and LV2 plugin.

---

### §2.3 Desktop integration (optional)

Create application launcher if not created by install script:

Steps:
1. Create desktop entry:

```sh
cat > ~/.local/share/applications/zynaddsubfx.desktop <<'EOF'
[Desktop Entry]
Name=ZynAddSubFX
Comment=Software Synthesizer
Exec=/opt/zyn-fusion/zynaddsubfx
Icon=zynaddsubfx
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Synthesizer;
EOF
```

2. Verify in application menu:

Search for "ZynAddSubFX" in wofi or application launcher.

Expected result: Can launch from application menu.

---

## §3 Install VCV Rack (Eurorack simulator)

VCV Rack is a virtual modular synthesizer platform. Used as standalone learning tool.

### §3.1 Download VCV Rack

Official site: [vcvrack.com](https://vcvrack.com/)

Steps:
1. Visit download page:

https://vcvrack.com/Rack

2. Download Linux build:

Click "Download Free" → Select Linux

Downloads: `Rack-{version}-lin-x64.zip`

3. Extract:

```sh
cd ~/Downloads
unzip Rack-2.6.6-lin-x64.zip
```

**Replace version** with current release.

Expected result: `Rack2Free/` directory with `Rack` executable.

---

### §3.2 Install VCV Rack

Steps:
1. Create versioned directory in /opt:

```sh
sudo mkdir -p /opt/vcv-rack
sudo mv Rack2Free /opt/vcv-rack/rack-2.6.6
```

**Use version number in directory name** for easy upgrades.

2. Set ownership:

```sh
sudo chown -R root:root /opt/vcv-rack/rack-2.6.6
```

3. Create symlink for current version:

```sh
sudo ln -sf /opt/vcv-rack/rack-2.6.6 /opt/vcv-rack/current
```

4. Test launch:

```sh
/opt/vcv-rack/current/Rack
```

Should launch VCV Rack.

5. Create wrapper script:

```sh
cat > ~/bin/vcv-rack <<'EOF'
#!/usr/bin/env bash
# VCV Rack launcher
cd /opt/vcv-rack/current
exec ./Rack "$@"
EOF
chmod +x ~/bin/vcv-rack
```

**Note:** `~/bin` is deployed via `bin-audacious/` package.

6. Test wrapper:

```sh
vcv-rack
```

Expected result: VCV Rack launches from anywhere.

---

### §3.3 Desktop integration

Create application launcher:

Steps:
1. Create desktop entry:

```sh
cat > ~/.local/share/applications/vcv-rack.desktop <<'EOF'
[Desktop Entry]
Name=VCV Rack
Comment=Virtual Eurorack Modular Synthesizer
Exec=/opt/vcv-rack/current/Rack
Icon=/opt/vcv-rack/current/icon.png
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Synthesizer;
EOF
```

2. Verify in application menu:

Search for "VCV Rack" in wofi.

Expected result: Can launch from application menu.

---

### §3.4 VCV account and plugins

Steps:
1. Launch VCV Rack
2. Click "Library" menu
3. Click "Register for VCV account"
4. Follow registration process
5. Log in via Library menu

6. Browse and install free plugins:
   - Click "Library" → "Browse online"
   - Filter by "Free"
   - Click "Subscribe" on desired plugins
   - Plugins install to `~/.local/share/Rack2/`

Expected result: VCV Rack configured with plugin library access.

---

## §4 Version management

### §4.1 Track installed versions

Create version tracking file:

```sh
cat > ~/dotfiles/docs/audacious/INSTALLED-AUDIO-VERSIONS.txt <<EOF
Audio Tools Installation Record
================================

sfizz
-----
Version: $(ls /usr/local/lib/libsfizz.so.* 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "not installed")
Installed: $(stat -c %y /usr/local/lib/lv2/sfizz.lv2 2>/dev/null | cut -d' ' -f1 || echo "unknown")
Location: /usr/local/lib/lv2/sfizz.lv2
Source: https://github.com/sfztools/sfizz/releases

ZynAddSubFX Fusion
------------------
Version: $(cat /opt/zyn-fusion/VERSION 2>/dev/null || echo "not installed")
Installed: $(stat -c %y /opt/zyn-fusion 2>/dev/null | cut -d' ' -f1 || echo "unknown")
Location: /opt/zyn-fusion
Source: https://zynaddsubfx.sourceforge.io/download.html

VCV Rack
--------
Version: $(ls /opt/vcv-rack/ 2>/dev/null | grep rack- | sed 's/rack-//' || echo "not installed")
Installed: $(stat -c %y /opt/vcv-rack/current 2>/dev/null | cut -d' ' -f1 || echo "unknown")
Location: /opt/vcv-rack/current -> $(readlink /opt/vcv-rack/current 2>/dev/null || echo "no symlink")
Source: https://vcvrack.com/Rack

Last updated: $(date +%Y-%m-%d)
EOF
```

Commit to dotfiles:

```sh
cd ~/dotfiles
git add docs/audacious/INSTALLED-AUDIO-VERSIONS.txt
git commit -m "docs: track installed audio tool versions"
```

---

### §4.2 Upgrading

**When to upgrade:**
- Security fixes
- Bug fixes affecting workflow
- New features needed

**When NOT to upgrade:**
- In middle of project (can break compatibility)
- No clear need (if it works, don't fix it)

**Upgrade procedure for each tool:**

**sfizz:**
1. Repeat §1 with new version
2. Old version is overwritten

**ZynAddSubFX:**
1. Backup old version:
   ```sh
   sudo mv /opt/zyn-fusion /opt/zyn-fusion.backup
   ```
2. Install new version (§2)
3. Test
4. Remove backup if successful

**VCV Rack:**
1. Install new version to versioned directory:
   ```sh
   sudo mv Rack2Free /opt/vcv-rack/rack-2.7.0
   ```
2. Update symlink:
   ```sh
   sudo ln -sf /opt/vcv-rack/rack-2.7.0 /opt/vcv-rack/current
   ```
3. Test
4. Remove old version if successful

---

## §5 Uninstallation

If tools need to be removed:

**sfizz:**
```sh
sudo rm -rf /usr/local/lib/lv2/sfizz.lv2
sudo rm /usr/local/lib/libsfizz*
```

**ZynAddSubFX:**
```sh
sudo rm -rf /opt/zyn-fusion
sudo rm -rf /usr/local/lib/lv2/ZynAddSubFX.lv2
rm ~/.local/share/applications/zynaddsubfx.desktop
```

**VCV Rack:**
```sh
sudo rm -rf /opt/vcv-rack
rm ~/bin/vcv-rack
rm ~/.local/share/applications/vcv-rack.desktop
rm -rf ~/.local/share/Rack2  # WARNING: Deletes all plugins and patches
```

---

## §6 Troubleshooting

### sfizz not visible in Ardour

**Cause:** LV2 cache not updated or plugin path not scanned.

**Fix:**
1. Force LV2 cache rebuild:
   ```sh
   rm -rf ~/.lv2
   lv2ls
   ```

2. Check Ardour plugin scan log:
   - Ardour → Edit → Preferences → Plugins → Scan

3. Verify plugin exists:
   ```sh
   ls -l /usr/local/lib/lv2/sfizz.lv2
   ```

---

### ZynAddSubFX JACK errors

**Cause:** PipeWire JACK bridge not configured or JACK ports conflicting.

**Fix:**
1. Verify JACK bridge:
   ```sh
   systemctl --user status pipewire-jack.service
   ```

2. Restart PipeWire:
   ```sh
   systemctl --user restart pipewire pipewire-pulse pipewire-jack
   ```

3. Launch with JACK backend explicitly:
   ```sh
   /opt/zyn-fusion/zynaddsubfx -O jack -I jack
   ```

---

### VCV Rack crashes on launch

**Cause:** Graphics driver issues or missing dependencies.

**Fix:**
1. Check for missing libraries:
   ```sh
   ldd /opt/vcv-rack/current/Rack | grep "not found"
   ```

2. Install missing dependencies (common):
   ```sh
   sudo apt install libgl1-mesa-glx libglu1-mesa libgtk-3-0
   ```

3. Try software rendering (slower):
   ```sh
   LIBGL_ALWAYS_SOFTWARE=1 /opt/vcv-rack/current/Rack
   ```

4. Check VCV Rack logs:
   ```sh
   cat ~/.local/share/Rack2/log.txt
   ```

---

### VCV Rack plugins won't download

**Cause:** Not logged into VCV account or network issue.

**Fix:**
1. Verify login:
   - Library → Log out
   - Library → Log in

2. Check network connectivity:
   ```sh
   ping library.vcvrack.com
   ```

3. Check firewall rules (if applicable)

4. Manual plugin installation:
   - Download .vcvplugin file from https://library.vcvrack.com/
   - Drag into VCV Rack window

---

## §7 Integration with Audacious workflow

These tools integrate with the broader Audacious pro audio stack:

**Ardour projects:**
- sfizz: Load SFZ sample libraries as instruments
- ZynAddSubFX: Use as soft synth for synthesis parts

**VCV Rack:**
- Standalone learning and experimentation
- Export audio for integration into Ardour projects
- JACK routing to Ardour (advanced)

**JACK/PipeWire routing:**
- All tools connect via PipeWire JACK bridge
- Configured via `pipewire-audacious/` dotfiles package
- Use `qpwgraph` or `helvum` for visual patching

---

## Appendix A: Why Manual Installation?

**Not in Debian repos because:**
- **sfizz:** Not packaged for Debian Trixie as of 2025
- **ZynAddSubFX Fusion:** Fusion UI (3.x) requires specific build, old 2.x in repos
- **VCV Rack:** Proprietary plugins and licensing model not compatible with Debian

**Advantages of manual install:**
- Latest versions
- Control over upgrade timing (critical for stable pro audio projects)
- Better upstream support

**Disadvantages:**
- Manual security updates
- No automatic dependency resolution
- More complex to track and document

---

## Appendix B: Cross-References

**Related documentation:**
- `docs/audacious/install-audacious.md` — Full system installation
- `docs/audacious/install-audacious.md` — Audacious system overview + install steps
- `ardour-audacious/` — Ardour DAW configuration package
- `pipewire-audacious/` — PipeWire audio routing configuration

---

## Appendix C: Sources

- [sfizz on GitHub](https://github.com/sfztools/sfizz)
- [sfizz releases](https://github.com/sfztools/sfizz/releases)
- [ZynAddSubFX download page](https://zynaddsubfx.sourceforge.io/download.html)
- [Zyn-Fusion build instructions](https://github.com/zynaddsubfx/zyn-fusion-build/wiki/Building-on-Linux)
- [VCV Rack official site](https://vcvrack.com/)
- [VCV Rack installation manual](https://vcvrack.com/manual/Installing)
- [VCV Rack plugin library](https://library.vcvrack.com/)

---
