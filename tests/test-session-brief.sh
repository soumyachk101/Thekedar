#!/usr/bin/env bash
# test-session-brief.sh — prints STATE when present, silent otherwise, always exit 0.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
HOOK="$ROOT/hooks/session-brief.sh"

fails=0
check() {
  if [ "$3" -eq "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (expected exit %s, got %s)\n' "$1" "$2" "$3"; fails=$((fails + 1)); fi
}

# 1. no state file → silent, exit 0
SB="$(mktemp -d)"
out="$(CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" < /dev/null)"; code=$?
check "no STATE → exit 0" 0 "$code"
if [ -z "$out" ]; then printf '     ok: no STATE → no output\n'
else printf '   FAIL: expected empty output, got: %s\n' "$out"; fails=$((fails + 1)); fi
rm -rf "$SB"

# 2. with state + ACTIVE task → brief printed with pointers
SB="$(mktemp -d)"
mkdir -p "$SB/.thekedar/tasks" "$SB/.thekedar/changes"
printf '# PROJECT_STATE\n\n## Active task\n\n004 — sample task\n' > "$SB/.thekedar/PROJECT_STATE.md"
printf '# Task 004\n\n**Status:** ACTIVE\n' > "$SB/.thekedar/tasks/004-sample-task.md"
printf '# Change record\n' > "$SB/.thekedar/changes/task-003.md"
out="$(CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" < /dev/null)"; code=$?
check "with STATE → exit 0" 0 "$code"
case "$out" in
  *"THEKEDAR SESSION BRIEF"*"004 — sample task"*) printf '     ok: brief contains state content\n' ;;
  *) printf '   FAIL: brief missing state content\n'; fails=$((fails + 1)) ;;
esac
case "$out" in
  *"ACTIVE task file:"*"004-sample-task.md"*) printf '     ok: ACTIVE task pointer present\n' ;;
  *) printf '   FAIL: ACTIVE task pointer missing\n'; fails=$((fails + 1)) ;;
esac
case "$out" in
  *"Latest changelog:"*"task-003.md"*) printf '     ok: latest changelog pointer present\n' ;;
  *) printf '   FAIL: changelog pointer missing\n'; fails=$((fails + 1)) ;;
esac
rm -rf "$SB"

exit "$fails"
