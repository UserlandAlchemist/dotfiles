#!/usr/bin/env bash
# Show friendly sink names (Description) in a Wofi dmenu and switch default sink.
# Works with PipeWire's PulseAudio compatibility (pactl).

set -e

# Optional friendly overrides (left = pactl sink name, right = label you want)
# Example:
#  [ "alsa_output.usb-Corsair_Corsair_HS55_SURROUND-00.analog-stereo" ]="Headset (Corsair HS55)"
#  [ "alsa_output.pci-0000_00_1f.3.analog-stereo" ]="Speakers (Analog)"
#  [ "alsa_output.pci-0000_03_00.1.hdmi-stereo" ]="HDMI"
declare -A OVERRIDE
OVERRIDE["alsa_output.usb-Corsair_Corsair_HS55_SURROUND-00.analog-stereo"]="Headset (Corsair HS55)"
OVERRIDE["alsa_output.pci-0000_00_1f.3.analog-stereo"]="Speakers (Analog)"
OVERRIDE["alsa_output.pci-0000_03_00.1.hdmi-stereo"]="HDMI"

current="$(pactl get-default-sink 2>/dev/null || true)"

# Build a tab-separated menu: "label<TAB>name"
menu_lines=""
while IFS= read -r sink_name; do
	# Try to fetch a nice Description from pactl
	desc="$(pactl list sinks 2>/dev/null | awk -v n="$sink_name" '
    $1=="Name:" && $2==n {f=1}
    f && $1=="Description:" {sub(/^Description: /,""); print; exit}
  ')"
	[ -z "$desc" ] && desc="$sink_name" # fallback

	# Apply override label if present
	label="${OVERRIDE[$sink_name]:-$desc}"

	# Mark current default with a bullet
	if [ "$sink_name" = "$current" ]; then
		label="• $label"
	fi

	menu_lines="${menu_lines}${label}\t${sink_name}\n"
done <<EOF
$(pactl list short sinks | awk '{print $2}')
EOF

# Show menu (label only), capture the selected line
labels="$(printf "%b" "$menu_lines" | awk -F'\t' '{print $1}')"
choice="$(printf "%s\n" "$labels" | wofi --dmenu --prompt 'Audio Output:' -i)"
[ -z "$choice" ] && exit 0

# Map label back to sink name
sink="$(printf "%b" "$menu_lines" | awk -v c="$choice" -F'\t' '$1==c{print $2; exit}')"
[ -z "$sink" ] && exit 1

pactl set-default-sink "$sink"

# Optional: notify (requires mako/libnotify-bin)
if command -v notify-send >/dev/null 2>&1; then
	notify-send -a "Audio Output" "Audio output switched" "$choice"
fi
