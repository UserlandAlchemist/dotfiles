#!/usr/bin/env bash

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT

export PATH="$ROOT/spec/support/bin:$PATH"

SPEC_TMP_ROOT="${ROOT}/.tmp/spec"
mkdir -p "$SPEC_TMP_ROOT"
export SPEC_TMP_ROOT
