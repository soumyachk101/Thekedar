#!/usr/bin/env bash
# test-plugin.sh — the Claude Code plugin manifests are valid and internally
# consistent: JSON parses, declared component paths exist, hooks.json wires
# real hook scripts with ${CLAUDE_PLUGIN_ROOT}, and versions agree with VERSION.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PDIR="$ROOT/.claude-plugin"

fails=0
ok()  { printf '     ok: %s\n' "$1"; }
bad() { printf '   FAIL: %s\n' "$1"; fails=$((fails + 1)); }

# choose a JSON parser (python3 or jq); skip gracefully if neither (zero-dep law)
JSON=""
if command -v python3 >/dev/null 2>&1; then JSON=py
elif command -v jq >/dev/null 2>&1; then JSON=jq
fi
if [ -z "$JSON" ]; then
  printf '     ok: no python3/jq — plugin manifest checks skipped (zero-dep env)\n'
  exit 0
fi

jget() { # jget <file> <python-expr-on-d> <jq-filter>
  if [ "$JSON" = py ]; then
    python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print($2)" "$1" 2>/dev/null
  else
    jq -r "$3" "$1" 2>/dev/null
  fi
}
valid_json() {
  if [ "$JSON" = py ]; then python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$1" 2>/dev/null
  else jq -e . "$1" >/dev/null 2>&1; fi
}

# 1. all three manifests are valid JSON
for f in plugin.json hooks.json marketplace.json; do
  if [ -f "$PDIR/$f" ] && valid_json "$PDIR/$f"; then ok "$f is valid JSON"; else bad "$PDIR/$f missing or invalid JSON"; fi
done

# 2. plugin name + version present and version matches VERSION
pname="$(jget "$PDIR/plugin.json" "d.get('name','')" ".name")"
pver="$(jget "$PDIR/plugin.json" "d.get('version','')" ".version")"
if [ "$pname" = "thekedar" ]; then ok "plugin name is 'thekedar'"; else bad "plugin name '$pname' != thekedar"; fi
fver="$(tr -d '[:space:]' < "$ROOT/VERSION")"
if [ "$pver" = "$fver" ]; then ok "plugin version ($pver) matches VERSION ($fver)"; else bad "plugin version '$pver' != VERSION '$fver'"; fi

# 3. declared agent dirs + skills dir + hooks file all exist
for d in ".claude/agents/core" ".claude/agents/extended" "skills"; do
  if [ -d "$ROOT/$d" ]; then ok "declared path exists: $d/"; else bad "declared path missing: $d/"; fi
done
if [ -f "$PDIR/hooks.json" ]; then ok "hooks file present: .claude-plugin/hooks.json"; else bad "hooks.json missing"; fi

# 4. every command in hooks.json references a real hook script under hooks/
if [ "$JSON" = py ]; then
  cmds="$(python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
for ev,arr in d.items():
    for m in arr:
        for h in m.get("hooks",[]):
            print(h.get("command",""))
' "$PDIR/hooks.json" 2>/dev/null)"
else
  cmds="$(jq -r '.[][]?.hooks[]?.command // empty' "$PDIR/hooks.json" 2>/dev/null)"
fi
while IFS= read -r c; do
  [ -z "$c" ] && continue
  script="$(printf '%s' "$c" | sed -n 's/.*hooks\/\([a-z-]*\.sh\).*/\1/p')"
  if [ -z "$script" ]; then bad "hooks.json command has no hooks/<script>.sh: $c"; continue; fi
  # command must reference the plugin-root variable (matched as a literal string)
  # shellcheck disable=SC2016
  case "$c" in
    *'${CLAUDE_PLUGIN_ROOT}'*) ;;
    *) bad "hooks.json command must use the plugin-root variable: $c" ;;
  esac
  if [ -f "$ROOT/hooks/$script" ]; then ok "hooks.json -> hooks/$script exists"; else bad "hooks.json references missing hooks/$script"; fi
done <<EOF
$cmds
EOF

# 5. drift-check is orchestrator-invoked and must NOT be an event hook;
#    the four event hooks must all be wired.
if grep -q 'drift-check' "$PDIR/hooks.json"; then bad "drift-check must not be wired as an event hook"; else ok "drift-check correctly NOT an event hook"; fi
for h in session-brief scope-guard secret-guard munshi; do
  if grep -q "$h.sh" "$PDIR/hooks.json"; then ok "wired in plugin hooks: $h"; else bad "plugin hooks.json missing $h"; fi
done

# 6. marketplace lists the plugin with source "./"
msrc="$(jget "$PDIR/marketplace.json" "d['plugins'][0].get('source','')" ".plugins[0].source")"
if [ "$msrc" = "./" ]; then ok "marketplace plugin source is './'"; else bad "marketplace source '$msrc' != './'"; fi

exit "$fails"
