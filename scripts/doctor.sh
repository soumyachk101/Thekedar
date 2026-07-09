#!/usr/bin/env bash
# ============================================================
#  doctor.sh — Thekedar health check
#  Run from your project root:
#    bash .thekedar/scripts/doctor.sh
#
#  Checks every installed piece and live-tests the hooks.
#  Exit 0 = healthy (warnings allowed) · exit 1 = something broken.
# ============================================================
set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
OK=0; WARN=0; FAIL=0

ok()   { printf '  ✅ %s\n' "$*"; OK=$((OK + 1)); }
warn() { printf '  ⚠️  %s\n' "$*"; WARN=$((WARN + 1)); }
bad()  { printf '  ❌ %s\n' "$*"; FAIL=$((FAIL + 1)); }

printf '\n\033[1m🏗️  Thekedar doctor\033[0m\n'
printf '  project: %s\n\n' "$PROJ"

# ---- Agents ----
CORE_AGENTS="planner backend-dev frontend-dev error-checker security-auditor frontend-reviewer"
EXT_AGENTS="test-writer db-specialist api-designer docs-writer performance-auditor accessibility-auditor dependency-auditor devops-engineer refactor-specialist"

missing=""
for a in $CORE_AGENTS; do
  [ -f "$PROJ/.claude/agents/core/$a.md" ] || missing="$missing $a"
done
if [ -z "$missing" ]; then ok "core crew: all 6 agents present"
else bad "core crew missing:$missing (re-run install.sh)"; fi

extn=0
for a in $EXT_AGENTS; do
  [ -f "$PROJ/.claude/agents/extended/$a.md" ] && extn=$((extn + 1))
done
if [ "$extn" -eq 9 ]; then ok "extended crew: all 9 agents present"
elif [ "$extn" -eq 0 ]; then warn "extended crew not installed (optional — install.sh --full)"
else warn "extended crew partial: $extn/9 (re-run install.sh --full)"; fi

# gates must be read-only
for g in core/error-checker core/security-auditor core/frontend-reviewer \
         extended/performance-auditor extended/accessibility-auditor extended/dependency-auditor; do
  f="$PROJ/.claude/agents/$g.md"
  [ -f "$f" ] || continue
  if sed -n 's/^tools: //p' "$f" | head -n1 | grep -qE 'Write|Edit'; then
    bad "gate $g has Write/Edit tools — reviewers must be read-only"
  fi
done
ok "gates verified read-only (tool allowlists)"

# ---- Skills ----
missing=""
for s in thekedar thekedar-status thekedar-report thekedar-plan; do
  [ -f "$PROJ/.claude/skills/$s/SKILL.md" ] || missing="$missing $s"
done
if [ -z "$missing" ]; then ok "skills: all 4 present"
else bad "skills missing:$missing"; fi

# ---- Hooks: present, executable, and ALIVE ----
for h in munshi scope-guard secret-guard session-brief drift-check; do
  f="$PROJ/.claude/hooks/$h.sh"
  if [ ! -f "$f" ]; then bad "hook missing: $h.sh"; continue; fi
  [ -x "$f" ] || warn "hook not executable: $h.sh (chmod +x it)"
done

FIXTURE='{"tool_name":"Edit","tool_input":{"file_path":"doctor-selftest.txt","old_string":"a","new_string":"b"}}'
if [ -f "$PROJ/.claude/hooks/munshi.sh" ]; then
  if printf '%s' "$FIXTURE" | CLAUDE_PROJECT_DIR="$PROJ" bash "$PROJ/.claude/hooks/munshi.sh" >/dev/null 2>&1; then
    ok "munshi.sh live test: exit 0 (ledger line written)"
  else
    bad "munshi.sh returned non-zero — it must NEVER block"
  fi
fi
if [ -f "$PROJ/.claude/hooks/scope-guard.sh" ]; then
  if printf '%s' "$FIXTURE" | CLAUDE_PROJECT_DIR="$PROJ" bash "$PROJ/.claude/hooks/scope-guard.sh" >/dev/null 2>&1; then
    ok "scope-guard.sh live test: allows when no task is ACTIVE"
  else
    warn "scope-guard.sh blocked a no-ACTIVE-task edit — check .thekedar/tasks for a stale ACTIVE status"
  fi
fi
if [ -f "$PROJ/.claude/hooks/secret-guard.sh" ]; then
  if printf '%s' "$FIXTURE" | CLAUDE_PROJECT_DIR="$PROJ" bash "$PROJ/.claude/hooks/secret-guard.sh" >/dev/null 2>&1; then
    ok "secret-guard.sh live test: clean content passes"
  else
    bad "secret-guard.sh blocked clean content — false-positive config?"
  fi
fi

# ---- settings.json wiring ----
SETTINGS="$PROJ/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
  bad "settings.json missing — hooks are not wired"
else
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$SETTINGS" 2>/dev/null; then
      ok "settings.json is valid JSON"
    else
      bad "settings.json is NOT valid JSON — hooks silently dead until fixed"
    fi
  fi
  for h in session-brief scope-guard secret-guard munshi; do
    if grep -q "$h.sh" "$SETTINGS" 2>/dev/null; then
      ok "wired: $h"
    else
      bad "not wired in settings.json: $h (re-run install.sh)"
    fi
  done
fi

# ---- .thekedar state ----
if [ -d "$PROJ/.thekedar/tasks" ]; then ok ".thekedar/tasks/ exists"; else bad ".thekedar/tasks/ missing"; fi
if [ -d "$PROJ/.thekedar/changes" ]; then ok ".thekedar/changes/ exists"; else bad ".thekedar/changes/ missing"; fi
if [ -f "$PROJ/.thekedar/PROJECT_STATE.md" ]; then ok "PROJECT_STATE.md present"; else bad "PROJECT_STATE.md missing"; fi
if [ -f "$PROJ/.thekedar/config.md" ]; then ok "config.md present"; else warn "config.md missing (defaults apply)"; fi

na=$(grep -l '^\*\*Status:\*\* ACTIVE' "$PROJ/.thekedar/tasks"/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$na" -gt 1 ]; then bad "$na tasks are ACTIVE — the invariant is exactly one"; fi

# ---- Environment ----
if [ -d "$PROJ/.git" ]; then ok "git repository"
else warn "no git repo — checkpoints and drift-check disabled (git init recommended)"; fi
if command -v jq >/dev/null 2>&1; then ok "jq available (fast hook parsing)"
elif command -v python3 >/dev/null 2>&1; then ok "python3 available (hook parsing fallback)"
else warn "neither jq nor python3 — hooks degrade to grep heuristics"; fi

# ---- Verdict ----
printf '\n\033[1m%d ok · %d warnings · %d failures\033[0m\n' "$OK" "$WARN" "$FAIL"
if [ "$FAIL" -eq 0 ]; then
  printf 'Sab theek. Kaam shuru karo. 🏗️\n'
  exit 0
else
  printf 'Fix the ❌ items, then re-run. Adhura kaam site pe nahi chalta.\n'
  exit 1
fi
