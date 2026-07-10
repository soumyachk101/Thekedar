#!/usr/bin/env bash
# test-factory.sh — the catalog factory holds together:
# validate-all green on the repo · generators are deterministic ·
# gen-agent refuses bad input and never clobbers a golden file.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
F="$ROOT/scripts/factory"

fails=0
check() {
  if [ "$3" -eq "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (expected %s, got %s)\n' "$1" "$2" "$3"; fails=$((fails + 1)); fi
}

# 1. the coherence gate is green on the committed repo
bash "$F/validate-all.sh" >/dev/null 2>&1; code=$?
check "validate-all.sh green on the repo" 0 "$code"

# 2. individual validators each pass
bash "$F/validate-agents.sh" >/dev/null 2>&1;    check "validate-agents green" 0 "$?"
bash "$F/validate-knowledge.sh" >/dev/null 2>&1; check "validate-knowledge green" 0 "$?"
bash "$F/validate-links.sh" >/dev/null 2>&1;     check "validate-links green" 0 "$?"

# 3. generators are deterministic — regenerating produces no diff
#    (they're committed; a re-run must not change tracked output)
if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  before="$(git -C "$ROOT" status --porcelain catalog/INDEX.md docs/agents 2>/dev/null)"
  bash "$F/gen-index.sh" >/dev/null 2>&1
  bash "$F/gen-agent-docs.sh" >/dev/null 2>&1
  after="$(git -C "$ROOT" status --porcelain catalog/INDEX.md docs/agents 2>/dev/null)"
  if [ "$before" = "$after" ]; then printf '     ok: generators deterministic (no diff on re-run)\n'
  else printf '   FAIL: gen-index/gen-agent-docs produced a diff on re-run\n'; fails=$((fails + 1)); fi
else
  printf '     ok: generator determinism check skipped (no git)\n'
fi

# 4. gen-agent refuses to overwrite an existing (golden) agent
bash "$F/gen-agent.sh" planner >/dev/null 2>&1; code=$?
check "gen-agent refuses to clobber an existing agent (exit 1)" 1 "$code"

# 5. gen-agent refuses an unknown name (no catalog row)
bash "$F/gen-agent.sh" no-such-agent-xyz >/dev/null 2>&1; code=$?
check "gen-agent refuses a name with no catalog row (exit 1)" 1 "$code"

# 6. gen-agent with no argument → usage error
bash "$F/gen-agent.sh" >/dev/null 2>&1; code=$?
check "gen-agent with no argument errors (exit 1)" 1 "$code"

# 7. an orphan agent file (no catalog row) makes validate-agents FAIL
SB_AGENT="$ROOT/.claude/agents/core/__factory_test_orphan.md"
cat > "$SB_AGENT" <<'ORPHAN'
---
name: __factory_test_orphan
description: >
  MUST BE USED never — this is a factory test fixture.
tools: Read, Grep, Glob
model: haiku
---
## Process
1. nothing
## Output
nothing
## Rules
- nothing
ORPHAN
bash "$F/validate-agents.sh" >/dev/null 2>&1; code=$?
rm -f "$SB_AGENT"
check "orphan agent file (no catalog row) fails validate-agents" 1 "$code"

exit "$fails"
