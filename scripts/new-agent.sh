#!/usr/bin/env bash
# ============================================================
#  new-agent.sh — F16: scaffold a custom crew member
#  Usage, from your project root:
#    bash .thekedar/scripts/new-agent.sh <name> [--doer|--gate] [--model sonnet|haiku|opus|inherit]
#  Example:
#    bash .thekedar/scripts/new-agent.sh db-migrator --doer --model sonnet
#
#  Creates .claude/agents/custom/<name>.md from the agent
#  template with the frontmatter law pre-applied:
#    doer → Read, Write, Edit, Bash, Grep, Glob
#    gate → Read, Grep, Glob, Bash   (read-only, enforced)
# ============================================================
set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
NAME="${1:-}"
TYPE="doer"
MODEL="sonnet"

shift 2>/dev/null || true
while [ $# -gt 0 ]; do
  case "$1" in
    --doer)  TYPE="doer" ;;
    --gate)  TYPE="gate" ;;
    --model) shift; MODEL="${1:-sonnet}" ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

# ---- validate ----
if [ -z "$NAME" ]; then
  echo "usage: new-agent.sh <kebab-case-name> [--doer|--gate] [--model sonnet|haiku|opus|inherit]" >&2
  exit 1
fi
case "$NAME" in
  *[!a-z0-9-]*|-*|*-)
    echo "❌ name must be kebab-case: lowercase letters, digits, inner hyphens (got: $NAME)" >&2
    exit 1 ;;
esac
case "$MODEL" in
  sonnet|haiku|opus|inherit) ;;
  *) echo "❌ model must be sonnet|haiku|opus|inherit (got: $MODEL)" >&2; exit 1 ;;
esac

TEMPLATE=""
for c in "$PROJ/.thekedar/templates/agent-template.md" "$PROJ/templates/agent-template.md"; do
  [ -f "$c" ] && TEMPLATE="$c" && break
done
if [ -z "$TEMPLATE" ]; then
  echo "❌ agent-template.md not found (looked in .thekedar/templates/ and templates/) — re-run install.sh" >&2
  exit 1
fi

for existing in "$PROJ/.claude/agents/core/$NAME.md" \
                "$PROJ/.claude/agents/extended/$NAME.md" \
                "$PROJ/.claude/agents/custom/$NAME.md"; do
  if [ -f "$existing" ]; then
    echo "❌ agent '$NAME' already exists: $existing" >&2
    exit 1
  fi
done

if [ "$TYPE" = "gate" ]; then
  TOOLS="Read, Grep, Glob, Bash"
  ROLE="$NAME (read-only review gate)"
else
  TOOLS="Read, Write, Edit, Bash, Grep, Glob"
  ROLE="$NAME (specialist doer)"
fi

OUT="$PROJ/.claude/agents/custom/$NAME.md"
mkdir -p "$PROJ/.claude/agents/custom"

sed -e "s/{{NAME}}/$NAME/g" \
    -e "s/{{TOOLS}}/$TOOLS/g" \
    -e "s/{{MODEL}}/$MODEL/g" \
    -e "s/{{ROLE}}/$ROLE/g" \
    "$TEMPLATE" > "$OUT"

echo "✅ scaffolded: ${OUT#"$PROJ"/}  (type: $TYPE, model: $MODEL)"
echo ""
echo "Next steps:"
echo "  1. Edit it: replace {{TRIGGER}} and every <placeholder> — the description"
echo "     must read as a trigger ('MUST BE USED when …'), that drives delegation."
echo "  2. Gates keep NO Write/Edit in tools — that's the read-only guarantee."
echo "  3. RESTART your Claude Code session (agents load at session start)."
exit 0
