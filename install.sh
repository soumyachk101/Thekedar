#!/usr/bin/env bash
# ============================================================
#  Thekedar installer (v2)
#  Usage, from YOUR PROJECT ROOT:
#    bash /path/to/thekedar/install.sh            # core crew (6 agents)
#    bash /path/to/thekedar/install.sh --full     # + extended crew (9 more)
#    bash /path/to/thekedar/install.sh --all      # the whole catalog (109 agents)
#
#  Idempotent: safe to re-run, including after updates. Never
#  overwrites a differing file without backing it up to *.bak.
#  Never clobbers living state (PROJECT_STATE.md, config.md).
# ============================================================
set -u

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$(pwd)"
FULL=0
ALL=0

for arg in "$@"; do
  case "$arg" in
    --full) FULL=1 ;;
    --all)  ALL=1; FULL=1 ;;
    -h|--help)
      sed -n '2,11p' "${BASH_SOURCE[0]}"; exit 0 ;;
  esac
done

say()  { printf '  %s\n' "$*"; }
head_(){ printf '\n\033[1m%s\033[0m\n' "$*"; }

head_ "🏗️  Thekedar installer (v2)"
say "source : $SRC"
say "target : $DEST"
[ "$ALL" -eq 1 ] && say "mode   : --all (the whole catalog)"
[ "$ALL" -eq 0 ] && [ "$FULL" -eq 1 ] && say "mode   : --full (core + extended crew)"

if [ "$SRC" = "$DEST" ]; then
  say "⚠️  You're running this inside the thekedar repo itself."
  say "   cd into YOUR project first, then: bash $SRC/install.sh"
  exit 1
fi

[ -d "$DEST/.git" ] || say "⚠️  No .git here — checkpoints need git. Continuing anyway."

# The agent roster is DERIVED from catalog/agents.psv — the factory's single
# source of truth. Add a row there and both installers pick it up; never
# hand-list agent names here again.
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

CATEGORIES="core"
[ "$FULL" -eq 1 ] && CATEGORIES="core extended"
[ "$ALL"  -eq 1 ] && CATEGORIES="core extended languages frameworks domains ops reviewers"

HOOKS="munshi scope-guard secret-guard session-brief drift-check"
SKILLS="thekedar thekedar-status thekedar-report thekedar-plan"
TEMPLATES="task.md PROJECT_STATE.md changelog-entry.md config.md agent-template.md decision-record.md phase.md"
SCRIPTS="doctor.sh export-agents-md.sh new-agent.sh report.sh stats.sh"

# ---- 1. Directories ----
mkdir -p "$DEST/.claude/hooks" \
         "$DEST/.thekedar/tasks" "$DEST/.thekedar/changes" \
         "$DEST/.thekedar/templates" "$DEST/.thekedar/scripts"
for c in $CATEGORIES; do mkdir -p "$DEST/.claude/agents/$c"; done
for s in $SKILLS; do mkdir -p "$DEST/.claude/skills/$s"; done

# ---- 2. Copy files (backup on difference, never silent overwrite) ----
copy() { # copy <src> <dest>
  if [ -f "$2" ] && ! cmp -s "$1" "$2"; then
    cp "$2" "$2.bak" && say "backup : ${2#"$DEST"/} → .bak"
  fi
  cp "$1" "$2" && say "install: ${2#"$DEST"/}"
}

n_agents=0
for c in $CATEGORIES; do
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    copy "$SRC/.claude/agents/$c/$a.md" "$DEST/.claude/agents/$c/$a.md"
    n_agents=$((n_agents + 1))
  done < <(agents_in "$c")
done
[ "$n_agents" -gt 0 ] || { say "❌ catalog resolved 0 agents — refusing a no-op install."; exit 1; }

for s in $SKILLS; do
  copy "$SRC/skills/$s/SKILL.md" "$DEST/.claude/skills/$s/SKILL.md"
done
for h in $HOOKS; do
  copy "$SRC/hooks/$h.sh" "$DEST/.claude/hooks/$h.sh"
  chmod +x "$DEST/.claude/hooks/$h.sh"
done
for t in $TEMPLATES; do
  copy "$SRC/templates/$t" "$DEST/.thekedar/templates/$t"
done
for sc in $SCRIPTS; do
  copy "$SRC/scripts/$sc" "$DEST/.thekedar/scripts/$sc"
  chmod +x "$DEST/.thekedar/scripts/$sc"
done

# Living state: initialize only if absent, never clobber.
if [ ! -f "$DEST/.thekedar/PROJECT_STATE.md" ]; then
  cp "$SRC/templates/PROJECT_STATE.md" "$DEST/.thekedar/PROJECT_STATE.md"
  say "init   : .thekedar/PROJECT_STATE.md"
fi
if [ ! -f "$DEST/.thekedar/config.md" ]; then
  cp "$SRC/templates/config.md" "$DEST/.thekedar/config.md"
  say "init   : .thekedar/config.md"
fi

# ---- 3. Merge hook wiring into .claude/settings.json ----
SETTINGS="$DEST/.claude/settings.json"

if command -v python3 >/dev/null 2>&1; then
  python3 - "$SETTINGS" <<'PYEOF'
import json, os, sys

path = sys.argv[1]
cfg = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            cfg = json.load(f)
    except Exception:
        print(f"  ⚠️  {path} is not valid JSON — leaving it alone. Fix it and re-run.")
        sys.exit(0)

hooks = cfg.setdefault("hooks", {})

def has(event, needle):
    return any(needle in h.get("command", "")
               for m in hooks.get(event, []) for h in m.get("hooks", []))

def cmd(name):
    return {"type": "command",
            "command": 'bash "$CLAUDE_PROJECT_DIR/.claude/hooks/%s.sh"' % name}

changed = []

if not has("SessionStart", "session-brief.sh"):
    hooks.setdefault("SessionStart", []).append({"hooks": [cmd("session-brief")]})
    changed.append("session-brief")

pre = hooks.setdefault("PreToolUse", [])
for name in ("scope-guard", "secret-guard"):
    if not has("PreToolUse", name + ".sh"):
        blk = next((m for m in pre if m.get("matcher") == "Write|Edit|MultiEdit"), None)
        if blk is None:
            blk = {"matcher": "Write|Edit|MultiEdit", "hooks": []}
            pre.append(blk)
        blk.setdefault("hooks", []).append(cmd(name))
        changed.append(name)

if not has("PostToolUse", "munshi.sh"):
    hooks.setdefault("PostToolUse", []).append(
        {"matcher": "Write|Edit|MultiEdit", "hooks": [cmd("munshi")]})
    changed.append("munshi")

if changed:
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print("  merge  : .claude/settings.json (+ %s)" % ", ".join(changed))
else:
    print("  ok     : all hooks already wired")
PYEOF
else
  say "⚠️  python3 not found — merge this into $SETTINGS manually:"
  cat <<'JSONEOF'
  {
    "hooks": {
      "SessionStart": [
        { "hooks": [ { "type": "command",
          "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/session-brief.sh\"" } ] } ],
      "PreToolUse": [
        { "matcher": "Write|Edit|MultiEdit", "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/scope-guard.sh\"" },
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/secret-guard.sh\"" } ] } ],
      "PostToolUse": [
        { "matcher": "Write|Edit|MultiEdit", "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/munshi.sh\"" } ] } ]
    }
  }
JSONEOF
fi

# ---- 4. Done ----
head_ "✅ Done. Next steps:"
say "1. RESTART your Claude Code session (agents/skills/hooks load at session start)."
say "2. Health check: bash .thekedar/scripts/doctor.sh"
say "3. Say: \"build me <something>\" — thekedar takes over. Hisaab saaf."
say "   installed $n_agents agent(s) from: $CATEGORIES"
[ "$FULL" -eq 0 ] && say "   (more crew: --full for the 9 extended specialists, --all for the whole catalog)"
[ "$FULL" -eq 1 ] && [ "$ALL" -eq 0 ] && say "   (want every specialist in the catalog? re-run with --all)"
exit 0
