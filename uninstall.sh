#!/usr/bin/env bash
# ============================================================
#  Thekedar uninstaller
#  Usage, from your project root:
#    bash /path/to/thekedar/uninstall.sh
#
#  Removes: every agent listed in catalog/agents.psv (whatever the
#  installer could have placed), 4 skills, 5 hooks, and their
#  settings.json entries. Your custom agents are untouched.
#  KEEPS .thekedar/ — that's your project's history. Delete it
#  yourself if you truly want it gone.
# ============================================================
set -u

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$(pwd)"
say() { printf '  %s\n' "$*"; }

printf '\n\033[1m🏗️  Thekedar uninstaller\033[0m\n'
say "target : $DEST"

# Mirror of install.sh: the roster comes from catalog/agents.psv, so an
# uninstall can never leave behind agents a newer install shipped.
CATALOG="$SRC/catalog/agents.psv"
[ -f "$CATALOG" ] || { say "❌ catalog missing: $CATALOG — cannot resolve the agent roster."; exit 1; }

agents_in() { # agents_in <category> → one agent name per line
  awk -F'|' -v want="$1" '
    /^[[:space:]]*#/ { next }
    { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2) }
    $1 == "" || $1 == "name" { next }
    $2 == want { print $1 }
  ' "$CATALOG"
}

CATEGORIES="core extended languages frameworks domains ops reviewers"
HOOKS="munshi scope-guard secret-guard session-brief drift-check"
SKILLS="thekedar thekedar-status thekedar-report thekedar-plan"

for c in $CATEGORIES; do
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    [ -f "$DEST/.claude/agents/$c/$a.md" ] || continue
    rm -f "$DEST/.claude/agents/$c/$a.md" && say "removed: .claude/agents/$c/$a.md"
  done < <(agents_in "$c")
  rmdir "$DEST/.claude/agents/$c" 2>/dev/null || true
done
rmdir "$DEST/.claude/agents" 2>/dev/null || true

for s in $SKILLS; do
  rm -rf "$DEST/.claude/skills/$s" && say "removed: .claude/skills/$s/"
done
rmdir "$DEST/.claude/skills" 2>/dev/null || true

for h in $HOOKS; do
  rm -f "$DEST/.claude/hooks/$h.sh" && say "removed: .claude/hooks/$h.sh"
done
rmdir "$DEST/.claude/hooks" 2>/dev/null || true

rm -rf "$DEST/.thekedar/scripts" && say "removed: .thekedar/scripts/"
# Shipped content, not project history — goes with the crew that cites it.
[ -d "$DEST/.thekedar/knowledge" ] \
  && rm -rf "$DEST/.thekedar/knowledge" && say "removed: .thekedar/knowledge/"

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
