#!/usr/bin/env bash
# ============================================================
#  drift-check.sh — scope drift reporter
#
#  NOT a Claude Code hook event. The orchestrator calls it at
#  task end (§4 LOG step of the thekedar skill):
#
#    bash .claude/hooks/drift-check.sh .thekedar/tasks/004-slug.md
#
#  Compares the actual working-tree changes (git status) against
#  the task's declared "## Expected files" + "## Scope addition"
#  entries and prints ONE report line for the changelog:
#
#    DRIFT: none — 3 changed file(s), all within declared scope
#    DRIFT: 2 file(s) outside declared scope: src/a.ts, src/b.ts
#
#  IRON RULE: ALWAYS exits 0. It reports; it never gates.
#  (.thekedar/** is workflow-inherent and never counts as drift.)
# ============================================================

TASK="${1:-}"
PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"

[ -n "$TASK" ] && [ -f "$TASK" ] || { echo "DRIFT: n/a — task file not found: ${TASK:-<none given>}"; exit 0; }
command -v git >/dev/null 2>&1        || { echo "DRIFT: n/a — git unavailable"; exit 0; }
git -C "$PROJ" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
                                      || { echo "DRIFT: n/a — not a git repository"; exit 0; }

# ---- Actual changes: modified + staged + untracked, project-relative ----
CHANGED="$(git -C "$PROJ" status --porcelain 2>/dev/null \
  | sed -e 's/^...//' -e 's/.* -> //' -e 's/^"\(.*\)"$/\1/' || true)"

if [ -z "$CHANGED" ]; then
  echo "DRIFT: none — working tree clean"
  exit 0
fi

# ---- Declared allowlist (same extraction as scope-guard.sh) ----
ALLOW_RAW="$(awk '
  /^## (Expected files|Scope addition)/ { grab = 1; next }
  /^## /                                { grab = 0 }
  grab && /^[[:space:]]*[-*]/           { print }
' "$TASK" 2>/dev/null || true)"

in_scope() { # in_scope <relpath> → 0 if allowed
  _p="$1"
  while IFS= read -r line; do
    entry="$line"
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry#- }"
    entry="${entry#\* }"
    case "$entry" in
      *\`*\`*) entry="${entry#*\`}"; entry="${entry%%\`*}" ;;
      *)       entry="${entry%%" ("*}" ;;
    esac
    entry="${entry%%" — "*}"
    entry="${entry%%" -- "*}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    entry="${entry#./}"
    [ -z "$entry" ] && continue
    case "$entry" in \<*) continue ;; esac
    case "$_p" in
      "$entry" | "${entry%/}"/*) return 0 ;;
    esac
    # shellcheck disable=SC2254 # unquoted on purpose: entries may be globs
    case "$_p" in
      $entry) return 0 ;;
    esac
  done <<ALLOW_EOF
$ALLOW_RAW
ALLOW_EOF
  return 1
}

TOTAL=0
MISSES=""
while IFS= read -r path; do
  [ -z "$path" ] && continue
  case "$path" in .thekedar/*) continue ;; esac   # workflow state ≠ drift
  TOTAL=$((TOTAL + 1))
  if ! in_scope "$path"; then
    MISSES="${MISSES:+$MISSES, }$path"
  fi
done <<CHANGED_EOF
$CHANGED
CHANGED_EOF

if [ -z "$MISSES" ]; then
  echo "DRIFT: none — $TOTAL changed file(s), all within declared scope"
else
  N="$(printf '%s' "$MISSES" | awk -F', ' '{print NF}')"
  echo "DRIFT: $N file(s) outside declared scope: $MISSES"
fi
exit 0
