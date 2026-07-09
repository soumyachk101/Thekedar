#!/usr/bin/env bash
# ============================================================
#  Thekedar uninstaller
#  Usage, from your project root:
#    bash /path/to/thekedar/uninstall.sh
#
#  Removes: the 15 known agents, 4 skills, 5 hooks, and their
#  settings.json entries. Your custom agents are untouched.
#  KEEPS .thekedar/ — that's your project's history. Delete it
#  yourself if you truly want it gone.
# ============================================================
set -u

DEST="$(pwd)"
say() { printf '  %s\n' "$*"; }

printf '\n\033[1m🏗️  Thekedar uninstaller\033[0m\n'
say "target : $DEST"

CORE_AGENTS="planner backend-dev frontend-dev error-checker security-auditor frontend-reviewer"
EXT_AGENTS="test-writer db-specialist api-designer docs-writer performance-auditor accessibility-auditor dependency-auditor devops-engineer refactor-specialist"
HOOKS="munshi scope-guard secret-guard session-brief drift-check"
SKILLS="thekedar thekedar-status thekedar-report thekedar-plan"

for a in $CORE_AGENTS; do
  rm -f "$DEST/.claude/agents/core/$a.md" && say "removed: .claude/agents/core/$a.md"
done
for a in $EXT_AGENTS; do
  [ -f "$DEST/.claude/agents/extended/$a.md" ] \
    && rm -f "$DEST/.claude/agents/extended/$a.md" \
    && say "removed: .claude/agents/extended/$a.md"
done
rmdir "$DEST/.claude/agents/core" "$DEST/.claude/agents/extended" "$DEST/.claude/agents" 2>/dev/null || true

for s in $SKILLS; do
  rm -rf "$DEST/.claude/skills/$s" && say "removed: .claude/skills/$s/"
done
rmdir "$DEST/.claude/skills" 2>/dev/null || true

for h in $HOOKS; do
  rm -f "$DEST/.claude/hooks/$h.sh" && say "removed: .claude/hooks/$h.sh"
done
rmdir "$DEST/.claude/hooks" 2>/dev/null || true

rm -rf "$DEST/.thekedar/scripts" && say "removed: .thekedar/scripts/"

# ---- settings.json: strip our hook entries, keep everything else ----
SETTINGS="$DEST/.claude/settings.json"
if [ -f "$SETTINGS" ] && command -v python3 >/dev/null 2>&1; then
  python3 - "$SETTINGS" <<'PYEOF'
import json, sys

path = sys.argv[1]
try:
    with open(path) as f:
        cfg = json.load(f)
except Exception:
    print(f"  ⚠️  {path} is not valid JSON — remove thekedar hook entries manually.")
    sys.exit(0)

OURS = ("munshi.sh", "scope-guard.sh", "secret-guard.sh", "session-brief.sh", "drift-check.sh")
hooks = cfg.get("hooks", {})
changed = False

for event in list(hooks.keys()):
    new_matchers = []
    for m in hooks[event]:
        kept = [h for h in m.get("hooks", [])
                if not any(o in h.get("command", "") for o in OURS)]
        if len(kept) != len(m.get("hooks", [])):
            changed = True
        if kept:
            m["hooks"] = kept
            new_matchers.append(m)
    if new_matchers:
        hooks[event] = new_matchers
    else:
        if hooks.get(event):
            changed = True
        hooks.pop(event, None)

if not hooks:
    cfg.pop("hooks", None)

if changed:
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print("  clean  : .claude/settings.json (thekedar hook entries removed)")
else:
    print("  ok     : no thekedar entries in settings.json")
PYEOF
elif [ -f "$SETTINGS" ]; then
  say "⚠️  python3 not found — remove munshi/scope-guard/secret-guard/session-brief entries from $SETTINGS manually."
fi

printf '\n\033[1m✅ Uninstalled.\033[0m\n'
say "kept   : .thekedar/ (tasks, changelogs, ledgers — your project's history)"
say "         delete it yourself if you want a full wipe: rm -rf .thekedar"
exit 0
