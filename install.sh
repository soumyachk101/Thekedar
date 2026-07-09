#!/usr/bin/env bash
# ============================================================
#  Thekedar installer
#  Usage: run from YOUR PROJECT ROOT:
#    bash /path/to/thekedar/install.sh
#  Idempotent: safe to re-run. Never overwrites your edits
#  without backing them up to *.bak first.
# ============================================================
set -u

# Where this repo (the source) lives:
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Where we're installing to (the user's project):
DEST="$(pwd)"

say()  { printf '  %s\n' "$*"; }
head_(){ printf '\n\033[1m%s\033[0m\n' "$*"; }

head_ "🏗️  Thekedar installer"
say "source : $SRC"
say "target : $DEST"

if [ "$SRC" = "$DEST" ]; then
  say "⚠️  You're running this inside the thekedar repo itself."
  say "   cd into YOUR project first, then: bash $SRC/install.sh"
  exit 1
fi

[ -d "$DEST/.git" ] || say "⚠️  No .git here — checkpoints need git. Continuing anyway."

# ---- 1. Directories ----
mkdir -p "$DEST/.claude/agents" "$DEST/.claude/hooks" \
         "$DEST/.claude/skills/thekedar" \
         "$DEST/.thekedar/tasks" "$DEST/.thekedar/changes" \
         "$DEST/.thekedar/templates"

# ---- 2. Copy files (backup on difference, never silent overwrite) ----
copy() { # copy <src> <dest>
  if [ -f "$2" ] && ! cmp -s "$1" "$2"; then
    cp "$2" "$2.bak" && say "backup : $2 → $2.bak"
  fi
  cp "$1" "$2" && say "install: ${2#"$DEST"/}"
}

for a in planner backend-dev error-checker security-auditor frontend-reviewer; do
  copy "$SRC/.claude/agents/$a.md" "$DEST/.claude/agents/$a.md"
done
copy "$SRC/skills/thekedar/SKILL.md" "$DEST/.claude/skills/thekedar/SKILL.md"
copy "$SRC/hooks/munshi.sh"          "$DEST/.claude/hooks/munshi.sh"
chmod +x "$DEST/.claude/hooks/munshi.sh"
for t in task.md PROJECT_STATE.md changelog-entry.md; do
  copy "$SRC/templates/$t" "$DEST/.thekedar/templates/$t"
done
# PROJECT_STATE: initialize only if absent (it's living state, never clobber)
if [ ! -f "$DEST/.thekedar/PROJECT_STATE.md" ]; then
  cp "$SRC/templates/PROJECT_STATE.md" "$DEST/.thekedar/PROJECT_STATE.md"
  say "init   : .thekedar/PROJECT_STATE.md"
fi

# ---- 3. Merge hook into .claude/settings.json ----
SETTINGS="$DEST/.claude/settings.json"
HOOK_CMD='bash "$CLAUDE_PROJECT_DIR/.claude/hooks/munshi.sh"'

if command -v python3 >/dev/null 2>&1; then
  python3 - "$SETTINGS" <<'PYEOF'
import json, os, sys
path = sys.argv[1]
cfg = {}
if os.path.exists(path):
    try:
        with open(path) as f: cfg = json.load(f)
    except Exception:
        print(f"  ⚠️  {path} is not valid JSON — leaving it alone.")
        sys.exit(0)
entry = {
    "matcher": "Write|Edit|MultiEdit",
    "hooks": [{"type": "command",
               "command": 'bash "$CLAUDE_PROJECT_DIR/.claude/hooks/munshi.sh"'}],
}
post = cfg.setdefault("hooks", {}).setdefault("PostToolUse", [])
if not any("munshi.sh" in h.get("command", "")
           for m in post for h in m.get("hooks", [])):
    post.append(entry)
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2); f.write("\n")
    print("  merge  : .claude/settings.json (munshi hook wired)")
else:
    print("  ok     : munshi hook already wired")
PYEOF
else
  say "⚠️  python3 not found — add this to $SETTINGS manually:"
  cat <<JSONEOF
  {
    "hooks": { "PostToolUse": [ {
      "matcher": "Write|Edit|MultiEdit",
      "hooks": [ { "type": "command", "command": "$HOOK_CMD" } ]
    } ] }
  }
JSONEOF
fi

# ---- 4. Done ----
head_ "✅ Done. Next steps:"
say "1. RESTART your Claude Code session (agents load at session start)."
say "2. Say: \"build me <something>\" — thekedar takes over."
say "3. Watch .thekedar/changes/ fill up. Hisaab saaf."
say ""
say "Verify hook: echo '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"x\"}}' | bash .claude/hooks/munshi.sh && cat .thekedar/changes/ledger-*.md"
exit 0
