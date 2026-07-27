#!/usr/bin/env bash
# ============================================================
#  install-codex.sh — Thekedar for Codex
#  Usage, from YOUR PROJECT ROOT:
#    bash /path/to/thekedar/scripts/install-codex.sh
#    bash /path/to/thekedar/scripts/install-codex.sh --full
#    bash /path/to/thekedar/scripts/install-codex.sh --all
#
#  Installs repo-local Codex skills under .agents/skills, Codex hooks
#  under .codex/, and the same .thekedar/ project state files used by
#  Claude Code. Also writes AGENTS.md for durable workflow guidance.
# ============================================================
set -u

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$(pwd)"
FULL=0
ALL=0

for arg in "$@"; do
  case "$arg" in
    --full) FULL=1 ;;
    --all)  ALL=1; FULL=1 ;;
    -h|--help)
      sed -n '2,13p' "${BASH_SOURCE[0]}"; exit 0 ;;
  esac
done

say()  { printf '  %s\n' "$*"; }
head_(){ printf '\n\033[1m%s\033[0m\n' "$*"; }

head_ "Thekedar Codex installer"
say "source : $SRC"
say "target : $DEST"
[ "$ALL" -eq 1 ] && say "mode   : --all (AGENTS.md includes the whole catalog)"
[ "$ALL" -eq 0 ] && [ "$FULL" -eq 1 ] && say "mode   : --full (AGENTS.md includes core + extended crew)"

if [ "$SRC" = "$DEST" ]; then
  say "Refusing to install into the Thekedar source repo itself."
  say "cd into your project first, then run this script."
  exit 1
fi

mkdir -p "$DEST/.agents/skills" \
         "$DEST/.codex/hooks" \
         "$DEST/.thekedar/tasks" "$DEST/.thekedar/changes" \
         "$DEST/.thekedar/templates" "$DEST/.thekedar/scripts"

copy() { # copy <src> <dest>
  if [ -f "$2" ] && ! cmp -s "$1" "$2"; then
    cp "$2" "$2.bak" && say "backup : ${2#"$DEST"/} -> .bak"
  fi
  cp "$1" "$2" && say "install: ${2#"$DEST"/}"
}

SKILLS="thekedar thekedar-status thekedar-report thekedar-plan"
HOOKS="munshi scope-guard secret-guard session-brief drift-check"
TEMPLATES="task.md PROJECT_STATE.md changelog-entry.md config.md agent-template.md decision-record.md phase.md"
SCRIPTS="doctor.sh export-agents-md.sh new-agent.sh report.sh stats.sh"

for s in $SKILLS; do
  mkdir -p "$DEST/.agents/skills/$s"
  copy "$SRC/skills/$s/SKILL.md" "$DEST/.agents/skills/$s/SKILL.md"
done

for h in $HOOKS; do
  copy "$SRC/hooks/$h.sh" "$DEST/.codex/hooks/$h.sh"
  chmod +x "$DEST/.codex/hooks/$h.sh"
done

for t in $TEMPLATES; do
  copy "$SRC/templates/$t" "$DEST/.thekedar/templates/$t"
done
for sc in $SCRIPTS; do
  copy "$SRC/scripts/$sc" "$DEST/.thekedar/scripts/$sc"
  chmod +x "$DEST/.thekedar/scripts/$sc"
done
copy "$SRC/hooks/drift-check.sh" "$DEST/.thekedar/scripts/drift-check.sh"
chmod +x "$DEST/.thekedar/scripts/drift-check.sh"

if [ -d "$SRC/knowledge" ]; then
  mkdir -p "$DEST/.thekedar/knowledge"
  cp -R "$SRC/knowledge/." "$DEST/.thekedar/knowledge/"
  say "install: .thekedar/knowledge/"
fi

[ -f "$DEST/.thekedar/PROJECT_STATE.md" ] || copy "$SRC/templates/PROJECT_STATE.md" "$DEST/.thekedar/PROJECT_STATE.md"
[ -f "$DEST/.thekedar/config.md" ] || copy "$SRC/templates/config.md" "$DEST/.thekedar/config.md"

cat > "$DEST/.codex/hooks.json" <<'JSON'
{
  "description": "Thekedar project hooks for Codex.",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "PROJ=\"$(git rev-parse --show-toplevel 2>/dev/null || pwd)\"; CLAUDE_PROJECT_DIR=\"$PROJ\" bash \"$PROJ/.codex/hooks/session-brief.sh\"",
            "statusMessage": "Loading Thekedar project state"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "apply_patch|Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "PROJ=\"$(git rev-parse --show-toplevel 2>/dev/null || pwd)\"; CLAUDE_PROJECT_DIR=\"$PROJ\" bash \"$PROJ/.codex/hooks/scope-guard.sh\"",
            "statusMessage": "Checking Thekedar scope"
          },
          {
            "type": "command",
            "command": "PROJ=\"$(git rev-parse --show-toplevel 2>/dev/null || pwd)\"; CLAUDE_PROJECT_DIR=\"$PROJ\" bash \"$PROJ/.codex/hooks/secret-guard.sh\"",
            "statusMessage": "Checking for secrets"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "apply_patch|Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "PROJ=\"$(git rev-parse --show-toplevel 2>/dev/null || pwd)\"; CLAUDE_PROJECT_DIR=\"$PROJ\" bash \"$PROJ/.codex/hooks/munshi.sh\"",
            "statusMessage": "Recording Thekedar ledger"
          }
        ]
      }
    ]
  }
}
JSON
say "install: .codex/hooks.json"

# Generate AGENTS.md from the installed Claude-format source in this repo.
# The export is intentionally single-context guidance; Codex plugin skills
# are the richer invocation path, but AGENTS.md gives every Codex session a
# durable fallback and helps Antigravity/Cursor-style agents too.
TMP_CLAUDE="$DEST/.thekedar/.export-claude"
mkdir -p "$TMP_CLAUDE/.claude/agents"
CATEGORIES="core"
[ "$FULL" -eq 1 ] && CATEGORIES="core extended"
[ "$ALL" -eq 1 ] && CATEGORIES="core extended languages frameworks domains ops reviewers"
for c in $CATEGORIES; do
  mkdir -p "$TMP_CLAUDE/.claude/agents/$c"
  cp "$SRC/.claude/agents/$c/"*.md "$TMP_CLAUDE/.claude/agents/$c/" 2>/dev/null || true
done
( cd "$TMP_CLAUDE" && CLAUDE_PROJECT_DIR="$TMP_CLAUDE" bash "$SRC/scripts/export-agents-md.sh" "$DEST/AGENTS.md" >/dev/null 2>&1 )
rm -rf "$TMP_CLAUDE"
say "install: AGENTS.md"

head_ "Done. Next steps:"
say "1. Restart Codex in this project so .agents/skills, AGENTS.md, and hooks load."
say "2. Run: /skills and choose Thekedar, or ask with an explicit skill mention:"
say "   Use \$thekedar to build <something>"
say "3. Health check: bash .thekedar/scripts/doctor.sh"
exit 0
