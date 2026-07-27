#!/usr/bin/env bash
# Antigravity PreToolUse adapter.
# Maps Antigravity write-tool JSON to Thekedar's existing Claude-style guard
# event shape, then returns Antigravity's JSON decision contract.
set -u

INPUT="$(head -c 300000 2>/dev/null || true)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

allow() {
  printf '{"decision":"allow"}\n'
  exit 0
}

deny() {
  if command -v python3 >/dev/null 2>&1; then
    REASON="$1" python3 -c 'import json, os; print(json.dumps({"decision":"deny","reason":os.environ.get("REASON","Thekedar guard blocked this write.")}))' 2>/dev/null || printf '{"decision":"deny","reason":"Thekedar guard blocked this write."}\n'
  else
    printf '{"decision":"deny","reason":"Thekedar guard blocked this write."}\n'
  fi
  exit 0
}

command -v python3 >/dev/null 2>&1 || allow

MAPPED="$(printf '%s' "$INPUT" | python3 -c '
import json, os, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print("")
    raise SystemExit

tc = d.get("toolCall") or {}
name = tc.get("name") or ""
args = tc.get("args") or {}
workspace = (d.get("workspacePaths") or [os.getcwd()])[0]

target = (
    args.get("TargetFile")
    or args.get("AbsolutePath")
    or args.get("file_path")
    or args.get("path")
    or ""
)

tool_input = {"file_path": target}
if name == "write_to_file":
    tool_input["content"] = args.get("CodeContent") or args.get("content") or ""
elif name == "replace_file_content":
    tool_input["old_string"] = args.get("TargetContent") or ""
    tool_input["new_string"] = args.get("ReplacementContent") or ""
elif name == "multi_replace_file_content":
    edits = []
    for chunk in args.get("ReplacementChunks") or []:
        edits.append({
            "old_string": chunk.get("TargetContent") or chunk.get("targetContent") or "",
            "new_string": chunk.get("ReplacementContent") or chunk.get("replacementContent") or "",
        })
    tool_input["edits"] = edits

print(json.dumps({
    "session_id": d.get("conversationId", "antigravity"),
    "cwd": workspace,
    "hook_event_name": "PreToolUse",
    "tool_name": name,
    "tool_input": tool_input,
}))
' 2>/dev/null || true)"

[ -n "$MAPPED" ] || allow

PROJ="$(printf '%s' "$INPUT" | python3 -c '
import json, os, sys
try:
    d = json.load(sys.stdin)
    ws = d.get("workspacePaths") or []
    print(ws[0] if ws else os.getcwd())
except Exception:
    print(os.getcwd())
' 2>/dev/null || pwd)"

ERR="$(printf '%s' "$MAPPED" | CLAUDE_PROJECT_DIR="$PROJ" bash "$PLUGIN_ROOT/hooks/scope-guard.sh" 2>&1 >/dev/null)"
code=$?
[ "$code" -eq 2 ] && deny "$ERR"

ERR="$(printf '%s' "$MAPPED" | CLAUDE_PROJECT_DIR="$PROJ" bash "$PLUGIN_ROOT/hooks/secret-guard.sh" 2>&1 >/dev/null)"
code=$?
[ "$code" -eq 2 ] && deny "$ERR"

# Antigravity's documented PostToolUse payload does not include the completed
# tool call path, so accepted write calls are logged here after both guards pass.
printf '%s' "$MAPPED" | CLAUDE_PROJECT_DIR="$PROJ" bash "$PLUGIN_ROOT/hooks/munshi.sh" >/dev/null 2>&1 || true
allow
