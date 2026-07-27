#!/usr/bin/env bash
# ============================================================
#  install-antigravity.sh — Thekedar for Google Antigravity
#  Usage, from YOUR PROJECT ROOT:
#    bash /path/to/thekedar/scripts/install-antigravity.sh
#    bash /path/to/thekedar/scripts/install-antigravity.sh --full
#    bash /path/to/thekedar/scripts/install-antigravity.sh --all
#
#  Antigravity support is the portable AGENTS.md mode: one context
#  follows the same plan -> build -> review -> log workflow.
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
      sed -n '2,12p' "${BASH_SOURCE[0]}"; exit 0 ;;
  esac
done

say()  { printf '  %s\n' "$*"; }
head_(){ printf '\n\033[1m%s\033[0m\n' "$*"; }

head_ "Thekedar Antigravity installer"
say "source : $SRC"
say "target : $DEST"

if [ "$SRC" = "$DEST" ]; then
  say "Refusing to install into the Thekedar source repo itself."
  say "cd into your project first, then run this script."
  exit 1
fi

mkdir -p "$DEST/.thekedar/tasks" "$DEST/.thekedar/changes" \
         "$DEST/.thekedar/templates" "$DEST/.thekedar/scripts"

copy() { # copy <src> <dest>
  if [ -f "$2" ] && ! cmp -s "$1" "$2"; then
    cp "$2" "$2.bak" && say "backup : ${2#"$DEST"/} -> .bak"
  fi
  cp "$1" "$2" && say "install: ${2#"$DEST"/}"
}

for t in task.md PROJECT_STATE.md changelog-entry.md config.md agent-template.md decision-record.md phase.md; do
  copy "$SRC/templates/$t" "$DEST/.thekedar/templates/$t"
done
for sc in doctor.sh export-agents-md.sh new-agent.sh report.sh stats.sh; do
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
say "1. Restart/open the project in Antigravity so it reads AGENTS.md."
say "2. Ask: build me <something> using the Thekedar workflow."
say "3. For a status snapshot, ask: Thekedar status."
exit 0
