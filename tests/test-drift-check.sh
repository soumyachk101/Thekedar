#!/usr/bin/env bash
# test-drift-check.sh — reports drift accurately, ALWAYS exits 0.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
HOOK="$ROOT/hooks/drift-check.sh"

fails=0
check() {
  if [ "$3" -eq "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (expected exit %s, got %s)\n' "$1" "$2" "$3"; fails=$((fails + 1)); fi
}
expect_out() { # expect_out <desc> <substring> <output>
  case "$3" in
    *"$2"*) printf '     ok: %s\n' "$1" ;;
    *) printf '   FAIL: %s (wanted substring: %s | got: %s)\n' "$1" "$2" "$3"; fails=$((fails + 1)) ;;
  esac
}

SB="$(mktemp -d)"
trap 'rm -rf "$SB"' EXIT

# scratch git repo with a committed file
git -C "$SB" init -q
mkdir -p "$SB/src/auth" "$SB/.thekedar/tasks"
printf 'const a = 1;\n' > "$SB/src/auth/login.ts"
git -C "$SB" add -A
git -C "$SB" -c user.name=t -c user.email=t@t commit -qm init

TASK="$SB/.thekedar/tasks/004-sample-task.md"
cat > "$TASK" <<'TASKEOF'
# Task 004 — sample

**Status:** ACTIVE

## Expected files

- `src/auth/login.ts` (modify)
- src/auth/*.test.ts
TASKEOF
# task file is untracked but lives under .thekedar/ → never drift
git -C "$SB" add -A
git -C "$SB" -c user.name=t -c user.email=t@t commit -qm task

# 1. clean tree
out="$(CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" "$TASK")"; code=$?
check "clean tree exits 0" 0 "$code"
expect_out "clean tree reported" "working tree clean" "$out"

# 2. in-scope change only
printf 'const a = 2;\n' > "$SB/src/auth/login.ts"
out="$(CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" "$TASK")"; code=$?
check "in-scope change exits 0" 0 "$code"
expect_out "in-scope change → no drift" "DRIFT: none" "$out"

# 3. out-of-scope untracked file → drift named
printf 'rogue\n' > "$SB/rogue.ts"
out="$(CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" "$TASK")"; code=$?
check "drift case exits 0" 0 "$code"
expect_out "drift names the rogue file" "outside declared scope: rogue.ts" "$out"

# 4. missing task file → n/a, exit 0
out="$(CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" "$SB/.thekedar/tasks/999-none.md")"; code=$?
check "missing task file exits 0" 0 "$code"
expect_out "missing task reported n/a" "DRIFT: n/a" "$out"

# 5. not a git repo → n/a, exit 0
SB2="$(mktemp -d)"
mkdir -p "$SB2/.thekedar/tasks"
cp "$TASK" "$SB2/.thekedar/tasks/"
out="$(CLAUDE_PROJECT_DIR="$SB2" bash "$HOOK" "$SB2/.thekedar/tasks/004-sample-task.md")"; code=$?
check "non-git dir exits 0" 0 "$code"
expect_out "non-git reported n/a" "not a git repository" "$out"
rm -rf "$SB2"

exit "$fails"
