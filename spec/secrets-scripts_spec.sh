#!/usr/bin/env bash

Describe "secrets usb scripts"
It "fails verify-secrets-usb when mount is missing"
When run env SECRETS_USB="$SPEC_TMP_ROOT/missing" \
	script "$ROOT/scripts/verify-secrets-usb.sh"
The status should be failure
The output should include "Secrets USB not mounted"
End

It "fails create-gdrive-recovery-bundle when mount is missing"
When run env SECRETS_USB="$SPEC_TMP_ROOT/missing" \
	script "$ROOT/scripts/create-gdrive-recovery-bundle.sh"
The status should be failure
The output should include "Secrets USB not mounted"
End

It "fails clone-secrets-usb when mount is missing"
When run env SECRETS_USB="$SPEC_TMP_ROOT/missing" \
	script "$ROOT/scripts/clone-secrets-usb.sh"
The status should be failure
The output should include "Secrets USB not mounted"
End
End
