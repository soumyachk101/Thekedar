#!/usr/bin/env bash
# test-knowledge-ship.sh — the shared brain must reach the project.
#
# 79 agents cite `.thekedar/knowledge/<pack>.md` by literal path. Before this
# suite existed, neither install.sh nor the plugin bootstrap shipped knowledge/,
# so 208 citations pointed at nothing in every real install — while every
# validator stayed green, because they all ran against the source repo where
# knowledge/ obviously exists.
#
# So this suite asserts against an INSTALLED layout, never the repo: install for
# real, then resolve every citation the installed agents actually make.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

fails=0
check() { # check <desc> <expected> <actual>
  if [ "$3" -eq "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (expected %s, got %s)\n' "$1" "$2" "$3"; fails=$((fails + 1)); fi
}
exists() { # exists <desc> <path>
  if [ -e "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (missing: %s)\n' "$1" "$2"; fails=$((fails + 1)); fi
}
absent() { # absent <desc> <path>
  if [ ! -e "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (still present: %s)\n' "$1" "$2"; fails=$((fails + 1)); fi
}

# dangling <project-dir> → count of cited packs that do not exist there
dangling() {
  local proj="$1" n=0 ref
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    [ -f "$proj/$ref" ] || n=$((n + 1))
  done <<EOF
$(grep -roh '\.thekedar/knowledge/[A-Za-z0-9/_.-]*\.md' "$proj/.claude/agents" 2>/dev/null | sort -u)
EOF
  printf '%s' "$n"
}
# cited <project-dir> → count of distinct packs the installed agents cite
cited() {
  grep -roh '\.thekedar/knowledge/[A-Za-z0-9/_.-]*\.md' "$1/.claude/agents" 2>/dev/null \
    | sort -u | grep -c '' | tr -d ' '
}

SB="$(mktemp -d)"
trap 'rm -rf "$SB"' EXIT
git -C "$SB" init -q

# ---- 1. default install (core only) — core agents cite packs too ----
( cd "$SB" && bash "$ROOT/install.sh" >/dev/null 2>&1 )
exists "default install ships .thekedar/knowledge/" "$SB/.thekedar/knowledge"
n=$(cited "$SB")
if [ "$n" -gt 0 ]; then
  printf '     ok: core agents cite %s pack(s) — worth shipping\n' "$n"
else
  printf '   FAIL: core agents cite 0 packs (citation format changed?)\n'; fails=$((fails + 1))
fi
check "no dangling citations after default install" 0 "$(dangling "$SB")"

# ---- 2. --all: every one of the 109 agents' citations must resolve ----
( cd "$SB" && bash "$ROOT/install.sh" --all >/dev/null 2>&1 )
n=$(find "$SB/.claude/agents" -name '*.md' | wc -l | tr -d ' ')
check "--all installs 109 agents" 109 "$n"
n=$(cited "$SB")
if [ "$n" -ge 40 ]; then
  printf '     ok: full crew cites %s distinct pack(s)\n' "$n"
else
  printf '   FAIL: full crew cites only %s packs (expected >= 40)\n' "$n"; fails=$((fails + 1))
fi
check "no dangling citations after --all" 0 "$(dangling "$SB")"
exists "nested packs survive the copy (security/owasp/)" "$SB/.thekedar/knowledge/security/owasp"

# ---- 3. re-run is idempotent, not a duplicator ----
before=$(find "$SB/.thekedar/knowledge" -name '*.md' | wc -l | tr -d ' ')
( cd "$SB" && bash "$ROOT/install.sh" --all >/dev/null 2>&1 )
after=$(find "$SB/.thekedar/knowledge" -name '*.md' | wc -l | tr -d ' ')
check "re-run leaves pack count unchanged" "$before" "$after"

# ---- 4. uninstall takes the packs (shipped content, not project history) ----
( cd "$SB" && bash "$ROOT/uninstall.sh" >/dev/null 2>&1 )
absent "uninstall removes .thekedar/knowledge/" "$SB/.thekedar/knowledge"
exists "uninstall keeps .thekedar/changes/ (history)" "$SB/.thekedar/changes"

# ---- 5. plugin path: bootstrap must ship packs too ----
# Fresh project, no install.sh — only the SessionStart hook, as a plugin user
# would experience it.
PB="$(mktemp -d)"
git -C "$PB" init -q
( cd "$PB" && CLAUDE_PROJECT_DIR="$PB" CLAUDE_PLUGIN_ROOT="$ROOT" \
    bash "$ROOT/hooks/session-brief.sh" >/dev/null 2>&1 ); code=$?
check "plugin bootstrap exits 0" 0 "$code"
exists "plugin bootstrap ships .thekedar/knowledge/" "$PB/.thekedar/knowledge"
exists "  · a real pack landed" "$PB/.thekedar/knowledge/pitfalls/react.md"

# ---- 6. the regression that started this: a project bootstrapped by an OLDER
# ---- version already has .thekedar/, so the scaffolding gate is closed. The
# ---- packs must still arrive on the next session.
OLD="$(mktemp -d)"
git -C "$OLD" init -q
mkdir -p "$OLD/.thekedar/tasks" "$OLD/.thekedar/changes"   # pre-existing, no knowledge/
printf '# state\n' > "$OLD/.thekedar/PROJECT_STATE.md"
( cd "$OLD" && CLAUDE_PROJECT_DIR="$OLD" CLAUDE_PLUGIN_ROOT="$ROOT" \
    bash "$ROOT/hooks/session-brief.sh" >/dev/null 2>&1 ); code=$?
check "existing-project bootstrap exits 0" 0 "$code"
exists "packs backfill into a pre-existing .thekedar/" "$OLD/.thekedar/knowledge"
exists "  · PROJECT_STATE.md untouched" "$OLD/.thekedar/PROJECT_STATE.md"
n=$(grep -c 'state' "$OLD/.thekedar/PROJECT_STATE.md" 2>/dev/null || echo 0)
check "  · and not overwritten" 1 "$n"

rm -rf "$PB" "$OLD"
exit "$fails"
