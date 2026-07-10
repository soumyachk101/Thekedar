#!/usr/bin/env bash
# test-secret-guard.sh — clean allow(0) · AWS/JWT/private-key/token block(2) ·
# false-positive allows · fixture-path exclusion · fail-open.
#
# NOTE: fake secrets below are built by string CONCATENATION so this test
# file's own content never matches the guard's patterns (the guard would
# otherwise block edits to this very file — dogfooding hazard).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
HOOK="$ROOT/hooks/secret-guard.sh"
FIX="$HERE/fixtures"

fails=0
check() {
  if [ "$3" -eq "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (expected exit %s, got %s)\n' "$1" "$2" "$3"; fails=$((fails + 1)); fi
}

wr() { # wr <file_path> <content> → Write event JSON
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"%s"}}' "$1" "$2"
}

SB="$(mktemp -d)"
trap 'rm -rf "$SB"' EXIT

# Fake secrets, assembled at runtime (never literal in this file):
AWS_FAKE="AKIA""IOSFODNN7EXAMPLE"
JWT_FAKE="eyJ""hbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"".""eyJ""zdWIiOiIxMjM0NTY3ODkwLCJuYW1lIjoiVGVzdCJ9"".""SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJVadQssw5c"
PEM_FAKE="-----BEGIN RSA ""PRIVATE KEY-----"
GHP_FAKE="ghp_""abcdefghijklmnopqrstuvwxyz0123456789"

# 1. clean content → allow
wr "src/app.ts" "const x = process.env.API_KEY;" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "clean content allowed" 0 "$code"

# 2. AWS key (fixture) → block
err="$(CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" < "$FIX/secret-payload.json" 2>&1 >/dev/null)"; code=$?
check "AWS access key blocked (exit 2)" 2 "$code"
case "$err" in
  *SECRET-GUARD*) printf '     ok: block message names guard\n' ;;
  *) printf '   FAIL: block message wrong: %s\n' "$err"; fails=$((fails + 1)) ;;
esac

# 3. JWT → block
wr "src/auth.ts" "const t = \\\"$JWT_FAKE\\\";" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null; code=$?
check "JWT blocked (exit 2)" 2 "$code"

# 4. PEM private key header → block
wr "src/key.pem" "$PEM_FAKE" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null; code=$?
check "private key block blocked (exit 2)" 2 "$code"

# 5. GitHub token in an Edit new_string → block
printf '{"tool_name":"Edit","tool_input":{"file_path":"src/ci.ts","old_string":"a","new_string":"token = %s"}}' "$GHP_FAKE" \
  | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null; code=$?
check "GitHub token in Edit blocked (exit 2)" 2 "$code"

# 6. false positives → allow
wr "src/cfg.ts" "password = \\\"changeme\\\"; const k = process.env.AWS_ACCESS_KEY_ID;" \
  | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "env-var refs + placeholder password allowed" 0 "$code"

# 7. secret in old_string only (already in file, being REMOVED) → allow
printf '{"tool_name":"Edit","tool_input":{"file_path":"src/fix.ts","old_string":"key = %s","new_string":"key = process.env.AWS_KEY"}}' "$AWS_FAKE" \
  | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "secret only in old_string (removal) allowed" 0 "$code"

# 8. fixtures path exclusion → allow even with a secret
wr "tests/fixtures/fake-creds.json" "aws = $AWS_FAKE" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "fixtures/ path excluded" 0 "$code"

# 9. .example file exclusion → allow
wr ".env.example" "AWS_ACCESS_KEY_ID=$AWS_FAKE" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "*.example path excluded" 0 "$code"

# 10. path traversal disguised as fixtures/** → BLOCKED, not exclusion-matched
#     (regression for the v2.0.0 release-audit finding: "fixtures/../src/x"
#     string-matched the "fixtures/*" exclusion glob without the path ever
#     really being under fixtures/, letting a real secret through unscanned.)
wr "fixtures/../src/config/prod.env" "aws = $AWS_FAKE" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null; code=$?
check "traversal disguised as fixtures/** is blocked" 2 "$code"

# 11. path traversal disguised as .thekedar/** (the universal-bypass variant —
#     .thekedar/** is the FIRST exclusion checked in both guards)
wr ".thekedar/../src/config/prod-secrets.env" "aws = $AWS_FAKE" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null; code=$?
check "traversal disguised as .thekedar/** is blocked" 2 "$code"

# 12. a harmless ../ that still lands in a real excluded dir → allowed
#     (canonicalization must not over-block legitimate exclusion paths)
wr "fixtures/sub/../fake.json" "aws = $AWS_FAKE" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "a ../ that resolves back into fixtures/ is still excluded" 0 "$code"

# 10. malformed input → fail open
CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" < "$FIX/malformed.json"; code=$?
check "malformed input fails open (exit 0)" 0 "$code"

# 11. empty stdin → fail open
printf '' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; code=$?
check "empty stdin fails open (exit 0)" 0 "$code"

# 12b. glob-metacharacter segment must NOT expand against the cwd → still SCANNED
#      (regression for the second release-audit finding: `set -- $_p` was
#      unquoted, so `f*` glob-EXPANDED to a real `fixtures/` in cwd, hitting
#      the exclusion and letting a real secret through unscanned. The literal
#      write target is a directory named `f*`, which is NOT the fixtures dir.)
mkdir -p "$SB/fixtures"
( cd "$SB" && wr "$SB/f*/prod.env" "aws = $AWS_FAKE" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null ); code=$?
check "glob-char '*' segment not expanded to fixtures/ exclusion (scanned+blocked)" 2 "$code"

exit "$fails"
