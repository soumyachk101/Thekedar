#!/usr/bin/env bash
# Antigravity PreInvocation adapter.
# Bootstraps/prints the Thekedar session brief, then returns Antigravity JSON.
set -u

INPUT="$(head -c 200000 2>/dev/null || true)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if command -v python3 >/dev/null 2>&1; then
  PROJ="$(printf '%s' "$INPUT" | python3 -c '
import json, os, sys
try:
    d = json.load(sys.stdin)
    ws = d.get("workspacePaths") or []
    print(ws[0] if ws else os.getcwd())
except Exception:
    print(os.getcwd())
' 2>/dev/null || pwd)"
else
  PROJ="$(pwd)"
fi

BRIEF="$(CLAUDE_PROJECT_DIR="$PROJ" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$PLUGIN_ROOT/hooks/session-brief.sh" 2>/dev/null || true)"

if [ -z "$BRIEF" ] || ! command -v python3 >/dev/null 2>&1; then
  printf '{"injectSteps":[]}\n'
  exit 0
fi

BRIEF="$BRIEF" python3 -c '
import json, os
print(json.dumps({"injectSteps": [{"ephemeralMessage": os.environ.get("BRIEF", "")}]}))
' 2>/dev/null || printf '{"injectSteps":[]}\n'
