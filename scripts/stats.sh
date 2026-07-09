#!/usr/bin/env bash
# ============================================================
#  stats.sh — quick numbers, stdout only
#  Usage, from your project root:
#    bash .thekedar/scripts/stats.sh
#
#  Same counting rules as report.sh, no file written.
# ============================================================
set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TK="$PROJ/.thekedar"

if [ ! -d "$TK" ]; then
  echo "no .thekedar/ here — nothing to count." >&2
  exit 1
fi

todo=0; active=0; review=0; done_=0; blocked=0
for t in "$TK/tasks"/*.md; do
  [ -f "$t" ] || continue
  s="$(sed -n 's/^\*\*Status:\*\* *\([A-Z]*\).*/\1/p' "$t" | head -n1)"
  case "$s" in
    TODO)    todo=$((todo + 1)) ;;
    ACTIVE)  active=$((active + 1)) ;;
    REVIEW)  review=$((review + 1)) ;;
    DONE)    done_=$((done_ + 1)) ;;
    BLOCKED) blocked=$((blocked + 1)) ;;
  esac
done

edits=0; today=0; files_touched=0
if ls "$TK/changes"/ledger-*.md >/dev/null 2>&1; then
  edits="$(grep -h '^|' "$TK/changes"/ledger-*.md 2>/dev/null \
           | grep -cv -e '^| Time' -e '^|---' || true)"
  files_touched="$(grep -h '^|' "$TK/changes"/ledger-*.md 2>/dev/null \
                   | grep -v -e '^| Time' -e '^|---' \
                   | awk -F'|' '{gsub(/^ +| +$/,"",$4); if ($4!="") print $4}' \
                   | sort -u | wc -l | tr -d ' ')"
  TODAY_LEDGER="$TK/changes/ledger-$(date +%F).md"
  if [ -f "$TODAY_LEDGER" ]; then
    today="$(grep -c '^|' "$TODAY_LEDGER" 2>/dev/null || echo 0)"
    [ "$today" -ge 2 ] && today=$((today - 2))
  fi
fi

fix_loops=0
for c in "$TK/changes"/task-*.md; do
  [ -f "$c" ] || continue
  n="$(sed -n 's/.*Fix loops used:\*\* *\([0-9]*\).*/\1/p; s/.*Fix loops used: *\([0-9]*\).*/\1/p' "$c" | head -n1)"
  [ -n "$n" ] && fix_loops=$((fix_loops + n))
done

commits="—"
if command -v git >/dev/null 2>&1 && git -C "$PROJ" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commits="$(git -C "$PROJ" log --oneline 2>/dev/null | grep -c 'thekedar(task-' || true)"
fi

printf 'tasks     : %d done · %d todo · %d active · %d review · %d blocked\n' "$done_" "$todo" "$active" "$review" "$blocked"
printf 'edits     : %s logged (%s today) across %s unique files\n' "$edits" "$today" "$files_touched"
printf 'fix loops : %d used\n' "$fix_loops"
printf 'commits   : %s thekedar checkpoints\n' "$commits"
exit 0
