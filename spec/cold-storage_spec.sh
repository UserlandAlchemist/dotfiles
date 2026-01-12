#!/usr/bin/env bash

Describe "cold storage scripts"
It "fails backup when mount is missing"
When run env COLD_STORAGE_MOUNT="$SPEC_TMP_ROOT/missing" \
	script "$ROOT/cold-storage-audacious/.local/bin/cold-storage-backup.sh"
The status should be failure
The stderr should include "is not mounted"
End

It "runs reminder without error"
When run script "$ROOT/cold-storage-audacious/.local/bin/cold-storage-reminder.sh"
The status should be success
End
End
