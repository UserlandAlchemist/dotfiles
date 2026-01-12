#!/usr/bin/env bash

Describe "apt-proxy-detect.sh"
It "returns proxy url when ping succeeds"
When run env PING_MOCK=success \
	script "$ROOT/root-network-audacious/usr/local/bin/apt-proxy-detect.sh"
The status should be success
The output should include "http://192.168.1.154:3142"
End

It "returns DIRECT when probes fail"
When run env PING_MOCK=fail TIMEOUT_MOCK=fail \
	script "$ROOT/root-network-audacious/usr/local/bin/apt-proxy-detect.sh"
The status should be success
The output should include "DIRECT"
End
End
