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
#  PLUGIN BOOTSTRAP: when installed as a Claude Code plugin (no
#  install.sh run), $CLAUDE_PLUGIN_ROOT is set and the project has
#  no .thekedar/ yet. On first session we lay down the scaffolding
#  (dirs + templates + scripts + initial PROJECT_STATE/config) from
#  the plugin's bundled copies, so the orchestrator finds templates
#  and scripts at the same .thekedar/ paths it uses after install.sh.
#  Idempotent (only runs when .thekedar/ is absent) and exit-0-safe.
#
#  IRON RULE: ALWAYS exits 0. No state file → prints nothing.
# ============================================================

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# ---- plugin bootstrap (no-op outside plugin mode / after first run) ----
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ ! -d "$PROJ/.thekedar" ]; then
  {
    mkdir -p "$PROJ/.thekedar/tasks" "$PROJ/.thekedar/changes" \
             "$PROJ/.thekedar/templates" "$PROJ/.thekedar/scripts"
    for t in task.md PROJECT_STATE.md changelog-entry.md config.md \
             agent-template.md decision-record.md phase.md; do
      cp "$CLAUDE_PLUGIN_ROOT/templates/$t" "$PROJ/.thekedar/templates/$t" 2>/dev/null || true
    done
    for s in doctor.sh export-agents-md.sh new-agent.sh report.sh stats.sh; do
      cp "$CLAUDE_PLUGIN_ROOT/scripts/$s" "$PROJ/.thekedar/scripts/$s" 2>/dev/null || true
    done
    # drift-check is orchestrator-invoked (not an event hook), so make it
    # reachable at a stable project path in plugin mode too.
    cp "$CLAUDE_PLUGIN_ROOT/hooks/drift-check.sh" "$PROJ/.thekedar/scripts/drift-check.sh" 2>/dev/null || true
    [ -f "$PROJ/.thekedar/PROJECT_STATE.md" ] || \
      cp "$CLAUDE_PLUGIN_ROOT/templates/PROJECT_STATE.md" "$PROJ/.thekedar/PROJECT_STATE.md" 2>/dev/null || true
    [ -f "$PROJ/.thekedar/config.md" ] || \
      cp "$CLAUDE_PLUGIN_ROOT/templates/config.md" "$PROJ/.thekedar/config.md" 2>/dev/null || true
    echo "=== THEKEDAR: plugin bootstrap — created .thekedar/ scaffolding in this project ==="
    echo "Say \"build me <something>\" to start, or /thekedar-plan to plan first."
  } 2>/dev/null || true
fi

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
