#!/usr/bin/env bash
# Validates the mod's manifest and hooks module, then runs its *.test.ts files.
set -euo pipefail
cd "$(dirname "$0")/.."
claude plugin validate .
claude plugin test .
