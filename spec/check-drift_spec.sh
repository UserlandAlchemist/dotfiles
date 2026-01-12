#!/usr/bin/env bash

Describe "check-drift.sh"
  It "prints help"
    When run script "$ROOT/bin-common/.local/bin/check-drift.sh" --help
    The status should be success
    The output should include "USAGE:"
  End

  It "fails when the document is missing"
    When run script "$ROOT/bin-common/.local/bin/check-drift.sh" "$ROOT/spec/fixtures/missing.md"
    The status should be failure
    The output should include "Cannot find"
  End

  It "reports no drift when packages match"
    When run env APT_MARK_SHOWMANUAL=$'alpha\nbeta' \
      script "$ROOT/bin-common/.local/bin/check-drift.sh" "$ROOT/spec/fixtures/installed-software-test.md"
    The status should be success
    The output should include "No drift detected"
  End

  It "reports drift when packages differ"
    When run env APT_MARK_SHOWMANUAL=$'alpha\nbeta\nomega' \
      script "$ROOT/bin-common/.local/bin/check-drift.sh" "$ROOT/spec/fixtures/installed-software-test.md"
    The status should be failure
    The output should include "Drift detected"
  End
End
