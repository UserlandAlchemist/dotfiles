#!/usr/bin/env bash

Describe "select-audio-sink.sh"
It "exits cleanly when no choice is made"
When run env PACTL_SINKS=$'sink0\nsink1' PACTL_DEFAULT_SINK=sink0 \
	WOFI_CHOICE= \
	script "$ROOT/pipewire-audacious/.local/bin/select-audio-sink.sh"
The status should be success
The output should not include "Audio output switched"
End
End
