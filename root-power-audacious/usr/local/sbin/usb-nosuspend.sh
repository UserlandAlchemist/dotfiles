#!/bin/sh
# Force important HID devices (keyboard/mouse) out of USB autosuspend

for dev in /sys/bus/usb/devices/*; do
	vid=$(cat "$dev/idVendor" 2>/dev/null)
	pid=$(cat "$dev/idProduct" 2>/dev/null)

	case "$vid:$pid" in
	3434:0363 | 04d9:fc4d)
		if [ -w "$dev/power/control" ]; then
			echo on >"$dev/power/control"
		fi
		;;
	esac
done
