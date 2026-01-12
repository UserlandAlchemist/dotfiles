#!/usr/bin/env bash

setup_state() {
  rm -f "$SPEC_TMP_ROOT/astute-state"
}

Describe "astute-status.sh"
  BeforeEach "setup_state"

  It "reports up when the host responds"
    When run env PING_MOCK=success STATE_FILE="$SPEC_TMP_ROOT/astute-state" \
      script "$ROOT/bin-audacious/.local/bin/astute-status.sh"
    The status should be success
    The output should include "SRV UP"
  End

  It "reports asleep when the host is down"
    When run env PING_MOCK=fail STATE_FILE="$SPEC_TMP_ROOT/astute-state" \
      script "$ROOT/bin-audacious/.local/bin/astute-status.sh"
    The status should be success
    The output should include "SRV ZZZ"
  End

  It "reports waking when state file exists"
    mkdir -p "$SPEC_TMP_ROOT"
    touch "$SPEC_TMP_ROOT/astute-state"
    When run env PING_MOCK=fail STATE_FILE="$SPEC_TMP_ROOT/astute-state" \
      script "$ROOT/bin-audacious/.local/bin/astute-status.sh"
    The status should be success
    The output should include "SRV WAKING"
  End
End
