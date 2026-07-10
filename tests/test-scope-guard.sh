#!/usr/bin/env bash
# test-scope-guard.sh — in-scope allow(0) · out-of-scope block(2) ·
# no-active-task allow(0) · .thekedar allow · advisory mode · fail-open.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
HOOK="$ROOT/hooks/scope-guard.sh"
FIX="$HERE/fixtures"

fails=0
check() {
  if [ "$3" -eq "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (expected exit %s, got %s)\n' "$1" "$2" "$3"; fails=$((fails + 1)); fi
}

mktask() { # mktask <dir> <status>
  mkdir -p "$1/.thekedar/tasks"
  cat > "$1/.thekedar/tasks/004-sample-task.md" <<TASK
# Task 004 — sample task

**Status:** $2
**Depends on:** none

## Objective

Sample.

## In scope

- sample thing

## NOT in scope (the fence — do not cross)

- everything else

## Acceptance criteria

- [ ] sample check

## Expected files

- \`src/auth/login.ts\` (modify)
- \`src/auth/token.ts\` (new)
- src/auth/*.test.ts

## Notes

none
TASK
}

evt() { # evt <file_path> → event JSON on stdout
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"a","new_string":"b"}}' "$1"
}

SB="$(mktemp -d)"
trap 'rm -rf "$SB"' EXIT
mktask "$SB" "ACTIVE"

# 1. in-scope edit → allow
CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" < "$FIX/valid-edit.json"; code=$?
check "in-scope file allowed" 0 "$code"

# 2. out-of-scope edit → block with exit 2 + SCOPE-GUARD message
err="$(CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" < "$FIX/out-of-scope-edit.json" 2>&1 >/dev/null)"; code=$?
check "out-of-scope file blocked (exit 2)" 2 "$code"
case "$err" in
  *SCOPE-GUARD*004*) printf '     ok: block message names guard + task\n' ;;
  *) printf '   FAIL: block message wrong: %s\n' "$err"; fails=$((fails + 1)) ;;
esac

# 3. glob entry matches → allow
evt "src/auth/login.test.ts" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "glob allowlist entry (src/auth/*.test.ts) allowed" 0 "$code"

# 4. .thekedar/** always writable → allow
evt ".thekedar/tasks/004-sample-task.md" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check ".thekedar path always allowed" 0 "$code"

# 5. absolute path inside project resolves to in-scope → allow
evt "$SB/src/auth/token.ts" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "absolute in-scope path allowed" 0 "$code"

# 6. Scope addition honored → allow
cat >> "$SB/.thekedar/tasks/004-sample-task.md" <<'ADD'

## Scope addition

- `src/extra/helper.ts` — shared util needed by token.ts
ADD
evt "src/extra/helper.ts" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "scope-addition file allowed" 0 "$code"

# 7. no ACTIVE task → allow everything (trivial mode)
SB2="$(mktemp -d)"
mktask "$SB2" "REVIEW"
CLAUDE_PROJECT_DIR="$SB2" bash "$HOOK" < "$FIX/out-of-scope-edit.json"; code=$?
check "no ACTIVE task → allow" 0 "$code"
rm -rf "$SB2"

# 8. malformed input → fail open
CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" < "$FIX/malformed.json"; code=$?
check "malformed input fails open (exit 0)" 0 "$code"

# 9. no .thekedar at all → allow
SB3="$(mktemp -d)"
CLAUDE_PROJECT_DIR="$SB3" bash "$HOOK" < "$FIX/out-of-scope-edit.json"; code=$?
check "no task system → allow" 0 "$code"
rm -rf "$SB3"

# 10. advisory mode: config scope_guard: off → allow + ledger advisory line
SB4="$(mktemp -d)"
mktask "$SB4" "ACTIVE"
printf 'scope_guard: off\n' > "$SB4/.thekedar/config.md"
CLAUDE_PROJECT_DIR="$SB4" bash "$HOOK" < "$FIX/out-of-scope-edit.json"; code=$?
check "advisory mode allows out-of-scope" 0 "$code"
if grep -q "scope-advisory" "$SB4/.thekedar/changes/"ledger-*.md 2>/dev/null; then
  printf '     ok: advisory miss logged to ledger\n'
else
  printf '   FAIL: advisory line missing from ledger\n'; fails=$((fails + 1))
fi
rm -rf "$SB4"

# 11. advisory value with trailing comment (real config.md style) → still advisory
SB5="$(mktemp -d)"
mktask "$SB5" "ACTIVE"
printf 'scope_guard: off                      # off = advisory only (miss logged, never blocked)\n' > "$SB5/.thekedar/config.md"
CLAUDE_PROJECT_DIR="$SB5" bash "$HOOK" < "$FIX/out-of-scope-edit.json"; code=$?
check "advisory mode with trailing comment allows" 0 "$code"
rm -rf "$SB5"

# 12. path traversal: allowed dir + ../ escape to a real sibling → BLOCKED
#     (regression for the v2.0.0 release-audit finding: a raw glob/prefix
#     match on an unresolved path let "src/../outside/x" pass a "src/*"
#     allow-entry, since case-glob `*` matches ".." as literal text.)
evt "$SB/src/../outside/pwned.txt" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null; code=$?
check "traversal via allowed-dir/../escape is blocked" 2 "$code"

# 13. path traversal escaping the project root entirely → BLOCKED
evt "$SB/src/../../etc/passwd" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null; code=$?
check "traversal escaping the project root entirely is blocked" 2 "$code"

# 14. path traversal disguised as .thekedar/** (the universal-bypass variant)
evt "$SB/.thekedar/../src/unrelated/rogue.ts" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null; code=$?
check "traversal disguised as .thekedar/** is still checked, not auto-allowed" 2 "$code"

# 15. a harmless ../ that still lands back in scope → allowed (canonicalization
#     must not over-block legitimate paths that merely contain a "..")
evt "$SB/src/auth/../auth/login.ts" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "a ../ that resolves back into scope is still allowed" 0 "$code"

# 16. glob-metacharacter segment must NOT expand against the cwd → BLOCKED
#     (regression for the second release-audit finding: `set -- $_p` was
#     unquoted, so a literal path segment `s*` glob-EXPANDED to a real `src/`
#     in the cwd, sneaking an out-of-scope write past the fence. The literal
#     write target here is a directory named `s*`, which is not in scope.)
mkdir -p "$SB/src/auth"
( cd "$SB" && evt "$SB/s*/auth/login.ts" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null ); code=$?
check "glob-char '*' segment is not expanded against cwd (blocked)" 2 "$code"

# 17. bracket-glob segment likewise literal → BLOCKED
( cd "$SB" && evt "$SB/a[bc]/auth/login.ts" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null ); code=$?
check "glob-char '[...]' segment is not expanded against cwd (blocked)" 2 "$code"

exit "$fails"
