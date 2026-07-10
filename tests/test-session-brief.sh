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

# All non-plugin cases must run with CLAUDE_PLUGIN_ROOT unset so the plugin
# bootstrap never fires (it would otherwise create .thekedar/ and print).
run() { env -u CLAUDE_PLUGIN_ROOT CLAUDE_PROJECT_DIR="$1" bash "$HOOK" < /dev/null; }

# 1. no state file → silent, exit 0
SB="$(mktemp -d)"
out="$(run "$SB")"; code=$?
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
out="$(run "$SB")"; code=$?
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

# 3. PLUGIN MODE: CLAUDE_PLUGIN_ROOT set + no .thekedar → bootstrap scaffolds it.
#    Use the repo root as the plugin root (it has templates/ and scripts/).
SB="$(mktemp -d)"
out="$(CLAUDE_PLUGIN_ROOT="$ROOT" CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" < /dev/null)"; code=$?
check "plugin bootstrap → exit 0" 0 "$code"
for want in \
  ".thekedar/templates/task.md" \
  ".thekedar/templates/config.md" \
  ".thekedar/scripts/doctor.sh" \
  ".thekedar/scripts/drift-check.sh" \
  ".thekedar/PROJECT_STATE.md" \
  ".thekedar/config.md" \
  ".thekedar/tasks" \
  ".thekedar/changes"; do
  if [ -e "$SB/$want" ]; then printf '     ok: bootstrap created %s\n' "$want"
  else printf '   FAIL: bootstrap missing %s\n' "$want"; fails=$((fails + 1)); fi
done
case "$out" in
  *"plugin bootstrap"*) printf '     ok: bootstrap announced itself\n' ;;
  *) printf '   FAIL: no bootstrap message\n'; fails=$((fails + 1)) ;;
esac
# 4. second run (state now exists) must NOT re-bootstrap, still exit 0
out2="$(CLAUDE_PLUGIN_ROOT="$ROOT" CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" < /dev/null)"; code=$?
check "plugin second run → exit 0 (idempotent)" 0 "$code"
case "$out2" in
  *"plugin bootstrap"*) printf '   FAIL: re-bootstrapped on second run\n'; fails=$((fails + 1)) ;;
  *) printf '     ok: no re-bootstrap on second run\n' ;;
esac
rm -rf "$SB"

exit "$fails"
