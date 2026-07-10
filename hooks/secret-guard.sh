#!/usr/bin/env bash
# ============================================================
#  secret-guard.sh — PreToolUse hook (matcher: Write|Edit|MultiEdit)
#
#  Scans ONLY the content about to be written (Write.content,
#  Edit.new_string, MultiEdit.edits[].new_string) for
#  high-confidence secret formats. Confirmed hit → exit 2 and
#  the write is blocked with a stderr explanation.
#
#  HIGH-CONFIDENCE ONLY. No fuzzy "looks like a password"
#  heuristics — a false block burns fix loops and trust. If the
#  written content cannot be isolated (no jq/python3), the guard
#  fails OPEN: scanning the raw event JSON would also match
#  old_string (text already in the file) and cause false blocks.
#
#  Skipped paths (fake secrets legitimately live there):
#    .thekedar/** · */fixtures/** · */__mocks__/** ·
#    *.sample · *.example · *.template
#
#  Patterns: AWS AKIA key · PEM private key block · JWT ·
#  GitHub ghp_/github_pat_ · Slack xox· · Stripe sk_live_ ·
#  Anthropic sk-ant- · Google AIza
#
#  PATH CANONICALIZATION: file_path is resolved lexically (., ..)
#  before checking the exclusion list — otherwise
#  "fixtures/../src/config/prod.env" string-matches the
#  "fixtures/*" exclusion glob without ever really being under
#  fixtures/, letting a real secret through unscanned. Same
#  pure-string approach as scope-guard.sh (no realpath/readlink -f
#  — must work on not-yet-existing Write targets, portably).
#
#  LIMITATION: lexical resolution does not follow symlinks. A
#  secret written through a symlinked excluded path (e.g. a
#  fixtures/ entry that is a symlink out of the repo) is skipped.
#  Creating that symlink needs Bash — itself an unguarded write-
#  anywhere path — so this is defense-in-depth against the model
#  writing a secret to a normal source file, not a hard sandbox.
#  See docs/adr/0006 and SECURITY.md.
# ============================================================

INPUT="$(head -c 200000 2>/dev/null || true)"
PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# canon_abspath <path> <base> — lexically resolve . and .. against <base>
# (if <path> is relative) or in place (if absolute). No filesystem access.
canon_abspath() {
  _p="$1"
  case "$_p" in
    /*) ;;
    *)  _p="$2/$_p" ;;
  esac
  _stack=""
  _oldifs="$IFS"
  # Disable pathname expansion around the split: with globbing ON, an
  # unquoted `set -- $_p` would glob-EXPAND a segment like `f*` or `a[b]`
  # against the cwd (matching e.g. a real `fixtures/`), turning this
  # "lexical, no-filesystem" resolver into a filesystem-dependent bypass.
  # We still want IFS=/ word-splitting — only globbing must be off.
  case "$-" in *f*) _hadf=1 ;; *) _hadf=0 ;; esac
  set -f
  IFS=/
  # shellcheck disable=SC2086
  set -- $_p
  IFS="$_oldifs"
  [ "$_hadf" -eq 0 ] && set +f
  for _seg in "$@"; do
    case "$_seg" in
      ""|".") continue ;;
      "..")
        case "$_stack" in
          */*) _stack="${_stack%/*}" ;;
          *)   _stack="" ;;
        esac
        ;;
      *) _stack="$_stack/$_seg" ;;
    esac
  done
  printf '%s' "${_stack:-/}"
}

# canon_relpath <path> <project_root> — prints the canonical path relative
# to project_root, or a sentinel (matches no real exclusion pattern) if
# <path> resolves outside project_root — default to SCANNING in that case.
canon_relpath() {
  _abs="$(canon_abspath "$1" "$2")"
  _rootabs="$(canon_abspath "$2" "$2")"
  case "$_abs" in
    "$_rootabs")   printf '.' ;;
    "$_rootabs"/*) printf '%s' "${_abs#"$_rootabs"/}" ;;
    *)             printf '\001ESCAPED-PROJECT-ROOT\001' ;;
  esac
}

# ---- file_path (for path exclusions + the block message) ----
FILE=""
if command -v jq >/dev/null 2>&1; then
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
elif command -v python3 >/dev/null 2>&1; then
  FILE="$(printf '%s' "$INPUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass
' 2>/dev/null || true)"
fi
if [ -z "$FILE" ]; then
  FILE="$(printf '%s' "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null \
          | head -n1 | sed 's/.*:[[:space:]]*"\(.*\)"/\1/' || true)"
fi

REL="$FILE"
if [ -n "$FILE" ]; then
  REL="$(canon_relpath "$FILE" "$PROJ")"
fi
[ -z "$REL" ] && REL="(unknown file)"

# Places where fake/sample secrets are legitimate by convention.
case "$REL" in
  .thekedar/*|*/fixtures/*|fixtures/*|*/__mocks__/*|__mocks__/*|*.sample|*.example|*.template)
    exit 0 ;;
esac

# ---- Isolate the content being written (jq → python3, else fail open) ----
CONTENT=""
if command -v jq >/dev/null 2>&1; then
  CONTENT="$(printf '%s' "$INPUT" | jq -r '
    [ (.tool_input.content // empty),
      (.tool_input.new_string // empty),
      ((.tool_input.edits // [])[] | (.new_string // empty)) ]
    | join("\n")' 2>/dev/null || true)"
elif command -v python3 >/dev/null 2>&1; then
  CONTENT="$(printf '%s' "$INPUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin).get("tool_input", {})
    parts = [d.get("content", ""), d.get("new_string", "")]
    for e in d.get("edits", []) or []:
        parts.append(e.get("new_string", "") or "")
    print("\n".join(p for p in parts if p))
except Exception:
    pass
' 2>/dev/null || true)"
else
  exit 0
fi
[ -z "$CONTENT" ] && exit 0

scan() { printf '%s' "$CONTENT" | grep -qE -- "$1" 2>/dev/null; }

HIT=""
if   scan 'AKIA[0-9A-Z]{16}';                                              then HIT="AWS access key ID"
elif scan '-----BEGIN [A-Z ]*PRIVATE KEY-----';                            then HIT="private key block (PEM)"
elif scan 'eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}'; then HIT="JSON Web Token"
elif scan 'ghp_[A-Za-z0-9]{36}';                                           then HIT="GitHub personal access token"
elif scan 'github_pat_[A-Za-z0-9_]{22,}';                                  then HIT="GitHub fine-grained PAT"
elif scan 'xox[baprs]-[0-9A-Za-z-]{10,}';                                  then HIT="Slack token"
elif scan 'sk_live_[0-9A-Za-z]{16,}';                                      then HIT="Stripe live secret key"
elif scan 'sk-ant-[A-Za-z0-9_-]{16,}';                                     then HIT="Anthropic API key"
elif scan 'AIza[0-9A-Za-z_-]{35}';                                         then HIT="Google API key"
fi

[ -z "$HIT" ] && exit 0

case "$REL" in
  *ESCAPED-PROJECT-ROOT*) DISPLAY_PATH="(a path resolving outside the project directory)" ;;
  *)                      DISPLAY_PATH="$REL" ;;
esac
echo "SECRET-GUARD: blocked — the content being written to $DISPLAY_PATH matches a $HIT pattern. Never hardcode secrets: read from an environment variable (process.env.X / os.environ) and add a placeholder to .env.example instead. If this is a deliberately fake sample, put it under a fixtures/ directory or a *.example file." >&2
exit 2
