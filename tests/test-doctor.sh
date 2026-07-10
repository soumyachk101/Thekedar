#!/usr/bin/env bash
# test-doctor.sh — installed doctor should resolve project root from script path
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

fails=0
ok()   { printf '     ok: %s\n' "$1"; }
fail() { printf '   FAIL: %s\n' "$1"; fails=$((fails + 1)); }

SB="$(mktemp -d)"
trap 'rm -rf "$SB"' EXIT
git -C "$SB" init -q

( cd "$SB" && bash "$ROOT/install.sh" --full >/dev/null 2>&1 ); code=$?
if [ "$code" -eq 0 ]; then
  ok "full install exits 0"
else
  fail "full install exits 0 (got $code)"
fi

OUT="$(cd "$ROOT" && bash "$SB/.thekedar/scripts/doctor.sh" 2>&1)"; code=$?
if [ "$code" -eq 0 ]; then
  ok "doctor exits 0 when launched outside project root"
else
  fail "doctor exits 0 when launched outside project root (got $code)"
fi
if printf '%s\n' "$OUT" | grep -Fq "project: $SB"; then
  ok "doctor resolves installed project path"
else
  fail "doctor resolves installed project path"
fi

exit "$fails"
