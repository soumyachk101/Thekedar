#!/usr/bin/env bash
# ============================================================
#  scope-guard.sh — the fence of the Thekedar workflow
#  PreToolUse hook (matcher: Write|Edit|MultiEdit)
#
#  While a task is ACTIVE, edits are only allowed on files that
#  task declared under "## Expected files" and "## Scope addition".
#  A confirmed out-of-scope edit is blocked with exit 2; the
#  stderr message tells the model the escape hatch: declare a
#  Scope addition in the task file first, then edit.
#
#  FAIL-OPEN RULE: exit 2 only on a CONFIRMED out-of-scope hit.
#  Any internal failure, parse doubt, or missing file → exit 0.
#  A guard that bricks sessions is worse than no guard.
#
#  Always allowed:
#    · no ACTIVE task (trivial mode / between tasks)
#    · anything under .thekedar/  (state must stay writable)
#    · scope_guard: off|advisory in .thekedar/config.md →
#      advisory mode: miss is logged to the daily ledger, never blocked
# ============================================================

INPUT="$(head -c 100000 2>/dev/null || true)"
PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TASKS_DIR="$PROJ/.thekedar/tasks"

# Nothing to guard without a task system.
[ -d "$TASKS_DIR" ] || exit 0

# ---- Parse file_path: jq → python3 → grep, else fail open ----
FILE=""
if command -v jq >/dev/null 2>&1; then
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
elif command -v python3 >/dev/null 2>&1; then
  FILE="$(printf '%s' "$INPUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass
' 2>/dev/null || true)"
fi
if [ -z "$FILE" ]; then
  FILE="$(printf '%s' "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null \
          | head -n1 | sed 's/.*:[[:space:]]*"\(.*\)"/\1/' || true)"
fi
[ -z "$FILE" ] && exit 0

# Normalize to a project-relative path.
REL="$FILE"
case "$REL" in
  "$PROJ"/*) REL="${REL#"$PROJ"/}" ;;
esac
REL="${REL#./}"

# The workflow's own state must always stay writable.
case "$REL" in
  .thekedar/*) exit 0 ;;
esac

# ---- Find the ACTIVE task (none → trivial mode → allow) ----
ACTIVE="$(grep -l '^\*\*Status:\*\* ACTIVE' "$TASKS_DIR"/*.md 2>/dev/null | head -n1 || true)"
[ -z "$ACTIVE" ] && exit 0

TASK_ID="$(basename "$ACTIVE" .md)"
TASK_NUM="${TASK_ID%%-*}"
[ -z "$TASK_NUM" ] && TASK_NUM="$TASK_ID"

# ---- Build allowlist: list lines under Expected files / Scope addition ----
ALLOW_RAW="$(awk '
  /^## (Expected files|Scope addition)/ { grab = 1; next }
  /^## /                                { grab = 0 }
  grab && /^[[:space:]]*[-*]/           { print }
' "$ACTIVE" 2>/dev/null || true)"

MATCHED=0
while IFS= read -r line; do
  entry="$line"
  entry="${entry#"${entry%%[![:space:]]*}"}"       # ltrim
  entry="${entry#- }"
  entry="${entry#\* }"
  case "$entry" in
    *\`*\`*) entry="${entry#*\`}"; entry="${entry%%\`*}" ;;  # backticked path
    *)       entry="${entry%%" ("*}" ;;                      # strip "(new)" etc.
  esac
  entry="${entry%%" — "*}"                          # scope-addition "path — reason"
  entry="${entry%%" -- "*}"
  entry="${entry%"${entry##*[![:space:]]}"}"        # rtrim
  entry="${entry#./}"
  [ -z "$entry" ] && continue
  case "$entry" in \<*) continue ;; esac            # template placeholder line
  case "$REL" in
    "$entry" | "${entry%/}"/*) MATCHED=1; break ;;  # exact, or under a listed dir
  esac
  # shellcheck disable=SC2254 # unquoted on purpose: entries may be globs
  case "$REL" in
    $entry) MATCHED=1; break ;;
  esac
done <<ALLOW_EOF
$ALLOW_RAW
ALLOW_EOF

[ "$MATCHED" -eq 1 ] && exit 0

# ---- Miss: advisory mode logs, guard mode blocks ----
MODE="$(sed -n 's/^scope_guard:[[:space:]]*//p' "$PROJ/.thekedar/config.md" 2>/dev/null \
        | head -n1 | tr -d '[:space:]' || true)"
if [ "$MODE" = "off" ] || [ "$MODE" = "advisory" ]; then
  mkdir -p "$PROJ/.thekedar/changes" 2>/dev/null || exit 0
  printf '| %s | scope-advisory | %s (outside task %s) |\n' \
    "$(date +%T)" "$REL" "$TASK_NUM" \
    >> "$PROJ/.thekedar/changes/ledger-$(date +%F).md" 2>/dev/null || true
  exit 0
fi

echo "SCOPE-GUARD: $REL is outside task $TASK_NUM's declared files. Either add a \"## Scope addition\" entry (file + one-line reason) to the task file first, or leave this file alone." >&2
exit 2
