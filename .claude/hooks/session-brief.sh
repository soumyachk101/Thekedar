#!/usr/bin/env bash
# ============================================================
#  session-brief.sh — SessionStart hook
#
#  Prints .thekedar/PROJECT_STATE.md (plus pointers to the
#  ACTIVE task and the latest changelog) to stdout. Claude Code
#  injects SessionStart stdout into the new session's context —
#  so every fresh session starts already knowing where the
#  project stands. Zero-prompt resume.
#
#  IRON RULE: ALWAYS exits 0. No state file → prints nothing.
# ============================================================

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE="$PROJ/.thekedar/PROJECT_STATE.md"

[ -f "$STATE" ] || exit 0

echo "=== THEKEDAR SESSION BRIEF (auto-injected by session-brief.sh) ==="
# Cap defensively — a bloated state file must not flood the context.
head -c 8000 "$STATE" 2>/dev/null || true
echo ""

ACTIVE="$(grep -l '^\*\*Status:\*\* ACTIVE' "$PROJ/.thekedar/tasks"/*.md 2>/dev/null | head -n1 || true)"
[ -n "$ACTIVE" ] && echo "ACTIVE task file: ${ACTIVE#"$PROJ"/}"

# shellcheck disable=SC2012 # ls -t for mtime ordering; filenames are ours (no spaces)
LAST="$(ls -t "$PROJ/.thekedar/changes"/task-*.md 2>/dev/null | head -n1 || true)"
[ -n "$LAST" ] && echo "Latest changelog: ${LAST#"$PROJ"/}"

echo "=== END BRIEF — say \"continue\" to resume via the thekedar workflow ==="
exit 0
