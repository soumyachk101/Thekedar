#!/usr/bin/env bash
# test-munshi.sh — the ledger hook must log correctly and NEVER exit non-zero.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
HOOK="$ROOT/hooks/munshi.sh"
FIX="$HERE/fixtures"

fails=0
check() { # check <desc> <expected_exit> <actual_exit>
  if [ "$3" -eq "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (expected exit %s, got %s)\n' "$1" "$2" "$3"; fails=$((fails + 1)); fi
}
check_grep() { # check_grep <desc> <pattern> <file>
  if grep -q "$2" "$3" 2>/dev/null; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (pattern %s not found in %s)\n' "$1" "$2" "$3"; fails=$((fails + 1)); fi
}

SB="$(mktemp -d)"
trap 'chmod -R u+w "$SB" 2>/dev/null; rm -rf "$SB"' EXIT

# 1. valid event → exit 0 + ledger line with the file path
CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" < "$FIX/valid-edit.json"; code=$?
check "valid edit event exits 0" 0 "$code"
LEDGER="$(ls "$SB/.thekedar/changes/"ledger-*.md 2>/dev/null | head -n1)"
check_grep "ledger line written with file path" "src/auth/login.ts" "${LEDGER:-/nonexistent}"
check_grep "ledger has table header" "| Time | Tool | File |" "${LEDGER:-/nonexistent}"

# 2. malformed JSON → exit 0
CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" < "$FIX/malformed.json"; code=$?
check "malformed JSON exits 0" 0 "$code"

# 3. empty stdin → exit 0
printf '' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "empty stdin exits 0" 0 "$code"

# 4. huge input (300 KB, beyond the 100 KB cap) → exit 0
head -c 300000 /dev/zero | tr '\0' 'x' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "huge input exits 0" 0 "$code"

# 5. read-only changes dir → exit 0 (logging failure must not block)
SB2="$(mktemp -d)"
mkdir -p "$SB2/.thekedar/changes"
chmod 555 "$SB2/.thekedar/changes"
CLAUDE_PROJECT_DIR="$SB2" bash "$HOOK" < "$FIX/valid-edit.json"; code=$?
check "read-only ledger dir exits 0" 0 "$code"
chmod -R u+w "$SB2" 2>/dev/null; rm -rf "$SB2"

exit "$fails"
