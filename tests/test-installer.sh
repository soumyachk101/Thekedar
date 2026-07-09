#!/usr/bin/env bash
# test-installer.sh — fresh install · idempotent rerun · settings merge
# preserves user config · --full · uninstall keeps .thekedar + custom keys.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

fails=0
check() { # check <desc> <expected> <actual>
  if [ "$3" -eq "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (expected %s, got %s)\n' "$1" "$2" "$3"; fails=$((fails + 1)); fi
}
exists() { # exists <desc> <path>
  if [ -e "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (missing: %s)\n' "$1" "$2"; fails=$((fails + 1)); fi
}
absent() { # absent <desc> <path>
  if [ ! -e "$2" ]; then printf '     ok: %s\n' "$1"
  else printf '   FAIL: %s (still present: %s)\n' "$1" "$2"; fails=$((fails + 1)); fi
}

SB="$(mktemp -d)"
trap 'rm -rf "$SB"' EXIT
git -C "$SB" init -q

# pre-existing user settings that MUST survive
mkdir -p "$SB/.claude"
printf '{\n  "model": "opus",\n  "hooks": {}\n}\n' > "$SB/.claude/settings.json"

# 1. fresh core install
( cd "$SB" && bash "$ROOT/install.sh" >/dev/null 2>&1 ); code=$?
check "fresh install exits 0" 0 "$code"
n=$(find "$SB/.claude/agents/core" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
check "6 core agents installed" 6 "$n"
absent "no extended agents without --full" "$SB/.claude/agents/extended"
n=$(find "$SB/.claude/skills" -mindepth 2 -maxdepth 2 -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
check "4 skills installed" 4 "$n"
n=$(find "$SB/.claude/hooks" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
check "5 hooks installed" 5 "$n"
n=$(find "$SB/.claude/hooks" -name '*.sh' -perm -111 2>/dev/null | wc -l | tr -d ' ')
check "all hooks executable" 5 "$n"
n=$(find "$SB/.thekedar/templates" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
check "7 templates installed" 7 "$n"
n=$(find "$SB/.thekedar/scripts" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
check "5 scripts installed" 5 "$n"
exists "PROJECT_STATE initialized" "$SB/.thekedar/PROJECT_STATE.md"
exists "config.md initialized" "$SB/.thekedar/config.md"

# 2. settings merge: hooks wired AND user key preserved
for h in session-brief scope-guard secret-guard munshi; do
  if grep -q "$h.sh" "$SB/.claude/settings.json"; then printf '     ok: wired %s\n' "$h"
  else printf '   FAIL: %s not wired\n' "$h"; fails=$((fails + 1)); fi
done
if grep -q '"model": "opus"' "$SB/.claude/settings.json"; then
  printf '     ok: pre-existing user setting preserved\n'
else
  printf '   FAIL: user setting clobbered\n'; fails=$((fails + 1))
fi

# 3. idempotent rerun: no duplicate wiring, no backups of identical files
( cd "$SB" && bash "$ROOT/install.sh" >/dev/null 2>&1 ); code=$?
check "rerun exits 0" 0 "$code"
n=$(grep -c 'munshi.sh' "$SB/.claude/settings.json")
check "no duplicate munshi wiring after rerun" 1 "$n"
n=$(find "$SB/.claude" "$SB/.thekedar" -name '*.bak' 2>/dev/null | wc -l | tr -d ' ')
check "no .bak files from identical rerun" 0 "$n"

# 4. user-modified file gets backed up on next install
printf '# user hack\n' >> "$SB/.claude/hooks/munshi.sh"
( cd "$SB" && bash "$ROOT/install.sh" >/dev/null 2>&1 )
exists "modified file backed up to .bak" "$SB/.claude/hooks/munshi.sh.bak"

# 5. --full adds the extended crew
( cd "$SB" && bash "$ROOT/install.sh" --full >/dev/null 2>&1 ); code=$?
check "--full install exits 0" 0 "$code"
n=$(find "$SB/.claude/agents/extended" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
check "9 extended agents with --full" 9 "$n"

# 6. running inside the source repo refuses
( cd "$ROOT" && bash "$ROOT/install.sh" >/dev/null 2>&1 ); code=$?
check "refuses to install into itself (exit 1)" 1 "$code"

# 7. uninstall: crew gone, history + user settings kept
( cd "$SB" && bash "$ROOT/uninstall.sh" >/dev/null 2>&1 ); code=$?
check "uninstall exits 0" 0 "$code"
absent "core agents removed" "$SB/.claude/agents/core"
absent "extended agents removed" "$SB/.claude/agents/extended"
absent "thekedar skill removed" "$SB/.claude/skills/thekedar"
absent "hooks removed" "$SB/.claude/hooks/munshi.sh"
exists ".thekedar/ history kept" "$SB/.thekedar/PROJECT_STATE.md"
if grep -q '"model": "opus"' "$SB/.claude/settings.json"; then
  printf '     ok: user setting survives uninstall\n'
else
  printf '   FAIL: uninstall clobbered user setting\n'; fails=$((fails + 1))
fi
if grep -q 'munshi.sh' "$SB/.claude/settings.json"; then
  printf '   FAIL: hook wiring left behind after uninstall\n'; fails=$((fails + 1))
else
  printf '     ok: hook wiring removed from settings\n'
fi

exit "$fails"
