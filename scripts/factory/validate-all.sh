#!/usr/bin/env bash
# ============================================================
#  validate-all.sh — the 1000-file coherence gate.
#  Run from repo root: bash scripts/factory/validate-all.sh
#  CI calls this (see .github/workflows/validate.yml).
#
#  Runs, in order: catalog syntax → agents → knowledge → links.
#  Non-zero exit if ANY validator fails. This is what lets the
#  catalog scale past 1000 files without rotting: nothing merges
#  unless every generated file still traces to a catalog row, a
#  golden pattern, and a passing validator.
# ============================================================
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
CATALOG="$ROOT/catalog/agents.tsv"
RC=0

printf '\n\033[1m🏭  Thekedar factory — validate-all\033[0m\n'

# ---- 0. catalog syntax: each non-comment row has 7 pipe fields ----
printf '\n\033[1m▶ validate-catalog\033[0m\n'
csyntax=0
lineno=0
while IFS= read -r line; do
  lineno=$((lineno + 1))
  case "$line" in ''|'#'*) continue ;; esac
  case "$line" in "name |"*|"name|"*) continue ;; esac
  nf="$(printf '%s' "$line" | awk -F'|' '{print NF}')"
  if [ "$nf" -ne 7 ]; then
    printf '  ❌ agents.tsv line %s: %s fields, expected 7 (name|category|type|tools|model|krefs|trigger)\n' "$lineno" "$nf"
    csyntax=1
  fi
done < "$CATALOG"
if [ "$csyntax" -eq 0 ]; then printf '  ✅ validate-catalog clean\n'; else printf '  ❌ validate-catalog FAILED\n'; RC=1; fi

# ---- 1-3. the validators ----
bash "$HERE/validate-agents.sh"    || RC=1
bash "$HERE/validate-knowledge.sh" || RC=1
bash "$HERE/validate-links.sh"     || RC=1

printf '\n'
if [ "$RC" -eq 0 ]; then
  printf '\033[1m✅ validate-all GREEN — every file traces to catalog + validator, 0 orphans.\033[0m\n'
else
  printf '\033[1m❌ validate-all FAILED — do not commit a dirty catalog.\033[0m\n'
fi
exit "$RC"
