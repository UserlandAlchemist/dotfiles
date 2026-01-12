#!/usr/bin/env bash

Describe "wait-for-astute.sh"
  It "exits success when astute is reachable"
    When run env PING_MOCK=success WAKEONLAN_BIN="$ROOT/spec/support/bin/wakeonlan" \
      script "$ROOT/root-borg-audacious/usr/local/lib/borg/wait-for-astute.sh"
    The status should be success
  End

  It "fails after timeout when astute stays down"
    When run env PING_MOCK=fail WAKEONLAN_BIN="$ROOT/spec/support/bin/wakeonlan" \
      script "$ROOT/root-borg-audacious/usr/local/lib/borg/wait-for-astute.sh"
    The status should be failure
    The output should include "astute not ready after WOL"
  End
End
