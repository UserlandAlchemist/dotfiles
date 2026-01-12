#!/usr/bin/env bash

Describe "borg offsite scripts"
It "fails audacious-home when key is missing"
When run script "$ROOT/root-borg-audacious/usr/local/lib/borg-offsite/run-audacious-home.sh"
The status should be failure
The output should include "missing BorgBase SSH key"
End

It "fails astute-critical when key is missing"
When run script "$ROOT/root-borg-astute/usr/local/lib/borg-offsite/run-astute-critical.sh"
The status should be failure
The output should include "missing BorgBase SSH key"
End
End
