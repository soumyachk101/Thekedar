#!/usr/bin/env bash
# ============================================================
#  validate-agents.sh — the HARD GATE for the agent catalog.
#  Run from the repo root:  bash scripts/factory/validate-agents.sh
#
#  Enforces, bidirectionally (no orphans in either direction):
#    · every catalog row has a file at .claude/agents/<category>/<name>.md
#    · every agent .md has a catalog row
#  And per agent file:
#    · valid frontmatter with name/description/tools/model
#    · name field == filename
#    · description starts with "MUST BE USED"
#    · model ∈ {inherit,sonnet,haiku,opus}
#    · type=gate ⇒ tools have NO Write/Edit;  type=doer ⇒ tools have Write
#    · body has ## Process, one of ## Output|## Verdict, and ## Rules
#    · every knowledge-ref (col 6) resolves to a real knowledge/ file
#
#  Exit 0 = all green · exit 1 = any failure (CI gates on this).
#  Pure bash; no jq/python3 needed.
# ============================================================
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CATALOG="$ROOT/catalog/agents.tsv"
AGENTS_DIR="$ROOT/.claude/agents"
FAIL=0

err()  { printf '  ❌ %s\n' "$*"; FAIL=1; }
info() { printf '  ·  %s\n' "$*"; }

printf '\n\033[1m▶ validate-agents\033[0m\n'

[ -f "$CATALOG" ] || { err "catalog missing: $CATALOG"; exit 1; }

# ---- field extractors ----
fm() { sed -n "s/^$2:[[:space:]]*//p" "$1" | head -n1; }
desc_first() {
  awk '
    /^description:[[:space:]]*>/ { d=1; next }
    /^description:[[:space:]]*[^>[:space:]]/ { sub(/^description:[[:space:]]*/,""); print; exit }
    d && /^[[:space:]]+[^[:space:]]/ { sub(/^[[:space:]]+/,""); print; exit }
    d && /^[^[:space:]]/ { exit }
  ' "$1"
}

# ---- 1. parse catalog into lookup vars ----
# associative arrays (bash 3.2 on macOS has none) → use a delimited record string
CATALOG_NAMES=""
CAT_ROWS=""
# shellcheck disable=SC2034 # 'trigger' is the 7th column, read for shape, unused here
while IFS='|' read -r name category type tools model krefs trigger; do
  case "$name" in ''|'#'*|'name ') continue ;; esac
  name="$(printf '%s' "$name" | tr -d '[:space:]')"
  [ "$name" = "name" ] && continue
  category="$(printf '%s' "$category" | tr -d '[:space:]')"
  type="$(printf '%s' "$type" | tr -d '[:space:]')"
  tools="$(printf '%s' "$tools" | sed 's/^ *//; s/ *$//')"
  model="$(printf '%s' "$model" | tr -d '[:space:]')"
  krefs="$(printf '%s' "$krefs" | sed 's/^ *//; s/ *$//')"
  CATALOG_NAMES="$CATALOG_NAMES $name"
  # store row keyed by name using a newline-delimited record
  CAT_ROWS="$CAT_ROWS
$name	$category	$type	$tools	$model	$krefs"
done < "$CATALOG"

lookup() { # lookup <name> <field-1based-after-name: 1=cat 2=type 3=tools 4=model 5=krefs>
  printf '%s\n' "$CAT_ROWS" | awk -F'\t' -v n="$1" -v c="$2" '$1==n{print $(c+1); exit}'
}

# ---- 2. every catalog row → a file at the expected path ----
for name in $CATALOG_NAMES; do
  cat="$(lookup "$name" 1)"
  f="$AGENTS_DIR/$cat/$name.md"
  if [ ! -f "$f" ]; then
    err "catalog row '$name' (category $cat) has no file at .claude/agents/$cat/$name.md"
  fi
done

# ---- 3. every agent file → valid, and has a catalog row ----
count=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  count=$((count + 1))
  rel="${f#"$ROOT"/}"
  base="$(basename "$f" .md)"

  name="$(fm "$f" name)"
  tools="$(fm "$f" tools)"
  model="$(fm "$f" model)"
  d1="$(desc_first "$f")"

  [ -n "$name" ]  || err "$rel: missing 'name' frontmatter"
  [ -n "$tools" ] || err "$rel: missing 'tools' frontmatter"
  [ -n "$model" ] || err "$rel: missing 'model' frontmatter"

  [ "$name" = "$base" ] || err "$rel: name '$name' != filename '$base'"

  case "$d1" in
    "MUST BE USED"*) ;;
    *) err "$rel: description must start with 'MUST BE USED' (got: ${d1:0:40}...)" ;;
  esac

  case "$model" in
    inherit|sonnet|haiku|opus) ;;
    *) err "$rel: model '$model' not in {inherit,sonnet,haiku,opus}" ;;
  esac

  # body sections always required
  grep -q '^## Process' "$f" || err "$rel: missing '## Process' section"
  grep -q '^## Rules' "$f"   || err "$rel: missing '## Rules' section"

  # catalog membership + type-driven tool law + type-driven section law
  ctype="$(lookup "$base" 2)"
  if [ -z "$ctype" ]; then
    err "$rel: no catalog row for '$base' (orphan file — add it to catalog/agents.tsv)"
  else
    case "$ctype" in
      gate)
        printf '%s' "$tools" | grep -qE '\b(Write|Edit|MultiEdit)\b' \
          && err "$rel: type=gate must NOT have Write/Edit tools (read-only law)"
        grep -qE '^## (Output|Verdict)' "$f" \
          || err "$rel: gate must have a '## Verdict format' or '## Output' section" ;;
      doer)
        printf '%s' "$tools" | grep -q 'Write' \
          || err "$rel: type=doer must have the Write tool"
        grep -qE '^## (Output|Verdict)' "$f" \
          || err "$rel: doer must have a '## Output' section" ;;
      brain) ;;  # brains vary (planner returns a summary inline; no fixed Output heading required)
      *) err "$rel: catalog type '$ctype' invalid (brain|doer|gate)" ;;
    esac
  fi

  # knowledge-refs resolve
  krefs="$(lookup "$base" 5)"
  if [ -n "$krefs" ] && [ "$krefs" != "-" ]; then
    _oldifs="$IFS"; IFS=','
    # shellcheck disable=SC2086
    set -- $krefs
    IFS="$_oldifs"
    for kr in "$@"; do
      kr="$(printf '%s' "$kr" | sed 's/^ *//; s/ *$//')"
      [ -z "$kr" ] && continue
      [ -f "$ROOT/knowledge/$kr" ] || err "$rel: knowledge-ref 'knowledge/$kr' does not exist"
    done
  fi
done <<EOF
$(find "$AGENTS_DIR" -type f -name '*.md' 2>/dev/null | sort)
EOF

if [ "$FAIL" -eq 0 ]; then
  info "$count agent file(s) validated · $(printf '%s' "$CATALOG_NAMES" | wc -w | tr -d ' ') catalog row(s) · 0 orphans"
  printf '  ✅ validate-agents clean\n'
else
  printf '  ❌ validate-agents FAILED\n'
fi
exit "$FAIL"
