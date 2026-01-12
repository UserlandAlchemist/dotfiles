#!/usr/bin/env bash

Describe "test-backups.sh"
It "fails when not run as root"
When run script "$ROOT/scripts/test-backups.sh"
The status should be failure
The stderr should include "Run as root"
End
End
