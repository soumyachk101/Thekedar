#!/usr/bin/env bash
# ============================================================
#  validate-knowledge.sh — quality gate for knowledge/ packs.
#  Run from repo root: bash scripts/factory/validate-knowledge.sh
#
#  knowledge/ holds the crew's shared brain (security, patterns,
#  pitfalls, checklists). Enforces:
#    · every knowledge file is substantive (≥ MIN_LINES lines) —
#      no empty stubs padding the file count
#    · no orphan packs: every knowledge/<path> is referenced by
#      ≥ 1 agent row in catalog/agents.psv
#    · no dangling citations, the reverse direction: every
#      `.thekedar/knowledge/<path>` an agent BODY cites must exist
#      as knowledge/<path>. Checking only packs→catalog let 208
#      body citations point at a directory no installer shipped —
#      green in the repo, broken in every install. Both directions
#      or neither.
#
#  Until the knowledge library is built (Phases 12-13), knowledge/
#  is absent/empty and this validator passes with a note.
#  Exit 0 = green · exit 1 = any failure. Pure bash.
# ============================================================
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KDIR="$ROOT/knowledge"
CATALOG="$ROOT/catalog/agents.psv"
MIN_LINES=60
FAIL=0

err()  { printf '  ❌ %s\n' "$*"; FAIL=1; }
info() { printf '  ·  %s\n' "$*"; }

printf '\n\033[1m▶ validate-knowledge\033[0m\n'

if [ ! -d "$KDIR" ] || [ -z "$(find "$KDIR" -type f -name '*.md' 2>/dev/null | head -n1)" ]; then
  info "no knowledge/ packs yet (built in Phases 12-13) — nothing to validate"
  printf '  ✅ validate-knowledge clean\n'
  exit 0
fi

# all knowledge-refs declared by any agent (col 6, comma-separated)
REFS="$(awk -F'|' '
  /^#/ {next} NF<6 {next} $1 ~ /^[[:space:]]*name[[:space:]]*$/ {next}
  { gsub(/^[ \t]+|[ \t]+$/,"",$6); if ($6!="-" && $6!="") print $6 }
' "$CATALOG" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sort -u)"

count=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  # README.md files are indexes, not packs — skip them
  case "$(basename "$f")" in README.md) continue ;; esac

  count=$((count + 1))
  rel="${f#"$ROOT"/}"
  krel="${f#"$KDIR"/}"

  lines="$(grep -c '' "$f" 2>/dev/null || echo 0)"
  [ "$lines" -ge "$MIN_LINES" ] || err "$rel: only $lines lines (min $MIN_LINES) — stub, not a pack"

  if ! printf '%s\n' "$REFS" | grep -qxF "$krel"; then
    err "$rel: orphan pack — no agent row in catalog/agents.psv references 'knowledge/$krel'"
  fi
done <<EOF
$(find "$KDIR" -type f -name '*.md' 2>/dev/null | sort)
EOF

# ---- reverse direction: agent body citations must resolve ----
# Agents cite the INSTALLED path (.thekedar/knowledge/...); the repo stores the
# packs at knowledge/... . Strip the prefix and check the pack is really there.
cites=0
dangling=0
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  cites=$((cites + 1))
  [ -f "$KDIR/${ref#.thekedar/knowledge/}" ] || {
    err "dangling citation: '$ref' is cited by an agent but no such pack exists"
    dangling=$((dangling + 1))
  }
done <<EOF
$(grep -roh '\.thekedar/knowledge/[A-Za-z0-9/_.-]*\.md' "$ROOT/.claude/agents" 2>/dev/null | sort -u)
EOF

# A bare `knowledge/...` citation would resolve in the repo but not in a
# project, where the packs live under .thekedar/. Catch the wrong prefix too.
# Capture any leading path chars so '.thekedar/' is part of the match, then
# drop the correct ones — no grep -P (BSD grep on macOS runners lacks it).
while IFS= read -r bad; do
  [ -n "$bad" ] || continue
  err "wrong prefix: '$bad' — agents must cite '.thekedar/knowledge/...' (the installed path)"
done <<EOF
$(grep -roh '[A-Za-z./]*knowledge/[A-Za-z0-9/_.-]*\.md' "$ROOT/.claude/agents" 2>/dev/null \
   | grep -v '^\.thekedar/knowledge/' | sort -u)
EOF

if [ "$FAIL" -eq 0 ]; then
  info "$cites distinct agent citation(s) resolve · $dangling dangling"
  info "$count knowledge pack(s) validated · all ≥ $MIN_LINES lines · 0 orphans"
  printf '  ✅ validate-knowledge clean\n'
else
  printf '  ❌ validate-knowledge FAILED\n'
fi
exit "$FAIL"
