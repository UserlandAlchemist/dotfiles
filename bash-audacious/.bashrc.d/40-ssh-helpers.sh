# shellcheck shell=bash
# SSH connectivity helpers
# Provides smart wake-on-demand SSH functions for remote hosts

ssh-astute() {
	local host="astute"
	local mac="60:45:cb:9b:ab:3b"
	local max_wait=60

	# Quick check: already up with loaded keys?
	if ssh -o BatchMode=yes -o ConnectTimeout=2 "${host}" true 2>/dev/null; then
		ssh -A "${host}"
		return
	fi

	# Check if SSH port is reachable (distinguishes "down" from "needs passphrase")
	if nc -z -w2 "${host}" 22 2>/dev/null; then
		# SSH daemon is up, just need to authenticate (may prompt for passphrase)
		ssh -A "${host}"
		return
	fi

	# Host is down, send WOL
	echo "Waking ${host}..."
	wakeonlan "${mac}"

	# Wait for SSH daemon to respond
	echo "Waiting for ${host} (up to ${max_wait}s)..."
	local waited=0
	while [ ${waited} -lt ${max_wait} ]; do
		if nc -z -w1 "${host}" 22 2>/dev/null; then
			echo "${host} is up (${waited}s)"
			ssh -A "${host}"
			return
		fi

		# Progress indicator every 10 seconds
		if [ $((waited % 10)) -eq 0 ] && [ ${waited} -gt 0 ]; then
			echo "  ${waited}s elapsed..."
		fi

		sleep 1
		waited=$((waited + 1))
	done

	# Timeout - try connecting anyway in case nc is having issues
	echo "Timeout after ${max_wait}s, attempting connection..."
	ssh -A "${host}"
}
