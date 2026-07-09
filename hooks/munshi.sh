#!/usr/bin/env bash
# ============================================================
#  munshi.sh — the clerk of the Thekedar workflow
#  PostToolUse hook (matcher: Write|Edit|MultiEdit)
#
#  Reads the hook event JSON from stdin, appends one ledger
#  line per file edit to .thekedar/changes/ledger-YYYY-MM-DD.md
#
#  IRON RULE: this script ALWAYS exits 0. A logging failure
#  must never break the user's coding session. Every command
#  is defensive; every failure path is swallowed.
# ============================================================

# Read stdin (the event JSON). Cap size defensively.
INPUT="$(head -c 100000 2>/dev/null || true)"

# Resolve project dir: env var from Claude Code, else cwd.
PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LEDGER_DIR="$PROJ/.thekedar/changes"
LEDGER_FILE="$LEDGER_DIR/ledger-$(date +%F).md"

mkdir -p "$LEDGER_DIR" 2>/dev/null || exit 0

# ---- Parse tool_name and file_path: jq → python3 → grep ----
TOOL=""
FILE=""

if command -v jq >/dev/null 2>&1; then
  TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)"
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
elif command -v python3 >/dev/null 2>&1; then
  PARSED="$(printf '%s' "$INPUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get("tool_name",""))
    print(d.get("tool_input",{}).get("file_path",""))
except Exception:
    pass
' 2>/dev/null || true)"
  TOOL="$(printf '%s' "$PARSED" | sed -n 1p)"
  FILE="$(printf '%s' "$PARSED" | sed -n 2p)"
fi

# Last-resort heuristic if both parsers unavailable/failed.
if [ -z "$FILE" ]; then
  FILE="$(printf '%s' "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null \
          | head -n1 | sed 's/.*:[[:space:]]*"\(.*\)"/\1/' || true)"
fi
[ -z "$TOOL" ] && TOOL="edit"
[ -z "$FILE" ] && FILE="(unknown)"

# Make path relative to project root for readable ledgers.
case "$FILE" in
  "$PROJ"/*) FILE="${FILE#"$PROJ"/}" ;;
esac

# ---- Create ledger with header if absent ----
if [ ! -f "$LEDGER_FILE" ]; then
  {
    echo "# Munshi Ledger — $(date +%F)"
    echo ""
    echo "Every file edit this day, recorded automatically. Facts only;"
    echo "the story lives in \`changes/task-*.md\`."
    echo ""
    echo "| Time | Tool | File |"
    echo "|------|------|------|"
  } >> "$LEDGER_FILE" 2>/dev/null || exit 0
fi

# ---- Append the line ----
printf '| %s | %s | %s |\n' "$(date +%T)" "$TOOL" "$FILE" >> "$LEDGER_FILE" 2>/dev/null || true

exit 0
