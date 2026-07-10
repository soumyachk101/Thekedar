#!/usr/bin/env bash
# ============================================================
#  gen-agent.sh — scaffold ONE agent .md from its catalog row.
#  Usage, from repo root:
#    bash scripts/factory/gen-agent.sh <name>
#
#  Reads the row for <name> from catalog/agents.tsv and writes
#  .claude/agents/<category>/<name>.md from templates/agent-template.md
#  with the frontmatter (name/tools/model) and description trigger
#  filled in. The BODY stays as template placeholders — a Claude
#  Code session fills it following the category's golden file.
#
#  This is the factory's unit of production: add a catalog row,
#  gen-agent.sh makes the valid skeleton, Claude writes the body,
#  validate-agents.sh gates it. Refuses to overwrite an existing
#  agent (hand-written golden files are never clobbered).
# ============================================================
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CATALOG="$ROOT/catalog/agents.tsv"
TEMPLATE="$ROOT/templates/agent-template.md"
NAME="${1:-}"

[ -n "$NAME" ] || { echo "usage: gen-agent.sh <name>" >&2; exit 1; }
[ -f "$TEMPLATE" ] || { echo "❌ template missing: $TEMPLATE" >&2; exit 1; }

# find the row. NOTE: trim a COPY of $1 for the comparison and print the
# ORIGINAL $0 — modifying $1 in awk rebuilds $0 with OFS (spaces), which would
# destroy the '|' delimiters the field() extractor below depends on.
ROW="$(awk -F'|' -v n="$NAME" '
  /^#/ {next}
  { t=$1; gsub(/^[ \t]+|[ \t]+$/,"",t) }
  t==n { print; exit }
' "$CATALOG")"
[ -n "$ROW" ] || { echo "❌ no catalog row for '$NAME' in $CATALOG (add it first)" >&2; exit 1; }

field() { printf '%s' "$ROW" | awk -F'|' -v i="$1" '{gsub(/^[ \t]+|[ \t]+$/,"",$i); print $i}'; }
CATEGORY="$(field 2)"
TYPE="$(field 3)"
TOOLS="$(field 4)"
MODEL="$(field 5)"
TRIGGER="$(field 7)"

OUT="$ROOT/.claude/agents/$CATEGORY/$NAME.md"
if [ -f "$OUT" ]; then
  echo "❌ already exists: ${OUT#"$ROOT"/} — refusing to overwrite (hand-edit or delete first)" >&2
  exit 1
fi
mkdir -p "$ROOT/.claude/agents/$CATEGORY"

case "$TYPE" in
  gate) ROLE="$NAME (read-only $CATEGORY review gate)" ;;
  doer) ROLE="$NAME ($CATEGORY specialist)" ;;
  *)    ROLE="$NAME ($CATEGORY $TYPE)" ;;
esac

# Fill placeholders. Description trigger comes from the catalog so the
# skeleton already validates ("MUST BE USED when <trigger>").
sed -e "s#{{NAME}}#$NAME#g" \
    -e "s#{{TOOLS}}#$TOOLS#g" \
    -e "s#{{MODEL}}#$MODEL#g" \
    -e "s#{{ROLE}}#$ROLE#g" \
    -e "s#{{TRIGGER}}#$TRIGGER#g" \
    "$TEMPLATE" > "$OUT"

echo "✅ scaffolded ${OUT#"$ROOT"/}  (category: $CATEGORY, type: $TYPE, model: $MODEL)"
echo "   Next: a Claude session fills the body following the $CATEGORY golden file, then:"
echo "   bash scripts/factory/validate-agents.sh"
