#!/usr/bin/env bash
# ============================================================
#  tests/run-all.sh — zero-dependency test runner.
#  Runs every tests/test-*.sh; non-zero exit if any suite fails.
#  CI entry point (see .github/workflows/ci.yml).
# ============================================================
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

total=0
failed=0

printf '\n🏗️  Thekedar test run\n\n'
for t in "$HERE"/test-*.sh; do
  [ -f "$t" ] || continue
  total=$((total + 1))
  name="$(basename "$t")"
  printf '▶ %s\n' "$name"
  if bash "$t"; then
    printf '  ✅ %s\n\n' "$name"
  else
    printf '  ❌ %s\n\n' "$name"
    failed=$((failed + 1))
  fi
done

printf '%d suite(s) run, %d failed\n' "$total" "$failed"
[ "$failed" -eq 0 ]
