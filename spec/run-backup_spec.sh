#!/usr/bin/env bash

Describe "run-backup.sh"
  It "fails when the repository never becomes reachable"
    When run env BORG_LIST_FAIL=1 WAKEONLAN_BIN="$ROOT/spec/support/bin/wakeonlan" \
      script "$ROOT/root-borg-audacious/usr/local/lib/borg/run-backup.sh"
    The status should be failure
    The output should include "ERROR: Astute not ready after WOL"
  End
End
