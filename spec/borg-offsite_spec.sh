#!/usr/bin/env bash

Describe "borg offsite scripts"
It "fails audacious-home when key is missing"
When run env SRC="$ROOT" \
	PATTERNS="$ROOT/spec/fixtures/installed-software-test.md" \
	KEY="$ROOT/spec/fixtures/missing-key" \
	PASSFILE="$ROOT/spec/fixtures/installed-software-test.md" \
	script "$ROOT/root-borg-audacious/usr/local/lib/borg-offsite/run-audacious-home.sh"
The status should be failure
The stderr should include "missing BorgBase SSH key"
End

It "fails astute-critical when key is missing"
When run env SRC1="$ROOT" SRC2="$ROOT" \
	KEY="$ROOT/spec/fixtures/missing-key" \
	PASSFILE="$ROOT/spec/fixtures/installed-software-test.md" \
	script "$ROOT/root-borg-astute/usr/local/lib/borg-offsite/run-astute-critical.sh"
The status should be failure
The stderr should include "missing BorgBase SSH key"
End
End
