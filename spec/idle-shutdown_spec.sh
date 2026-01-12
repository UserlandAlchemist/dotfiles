#!/usr/bin/env bash

Describe "idle-shutdown.sh"
It "aborts when a shutdown inhibitor is present"
When run env MEDIA_WINDOW_SEC=1 CHECK_INTERVAL_SEC=1 \
	SYSTEMD_INHIBIT_OUTPUT=shutdown JELLYFIN_CHECK_REMOTE=0 \
	SYSTEMCTL_POWEROFF_OUTPUT=poweroff \
	script "$ROOT/bin-audacious/.local/bin/idle-shutdown.sh"
The status should be success
The output should not include "poweroff"
End
End
