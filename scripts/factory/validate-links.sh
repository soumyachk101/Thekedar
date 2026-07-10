#!/usr/bin/env bash
# ============================================================
#  validate-links.sh — every relative Markdown link resolves.
#  Run from repo root: bash scripts/factory/validate-links.sh
#
#  Scans every tracked *.md, extracts ](target) links, skips
#  http(s)/#anchor/mailto, resolves the rest relative to the
#  file's directory, and fails if the target does not exist.
#
#  Uses python3 when present (exact); falls back to pure bash.
#  Exit 0 = all resolve · exit 1 = any broken link.
# ============================================================
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1

printf '\n\033[1m▶ validate-links\033[0m\n'

if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PYEOF'
import os, re, subprocess, sys
try:
    files = subprocess.check_output(["git", "ls-files", "*.md"], text=True).split()
except Exception:
    files = []
    for dp, _, fns in os.walk("."):
        if "/.git" in dp: continue
        for fn in fns:
            if fn.endswith(".md"): files.append(os.path.join(dp, fn))
link_re = re.compile(r'\]\(([^)]+)\)')
broken = 0; scanned = 0
for f in files:
    scanned += 1
    base = os.path.dirname(f)
    try: text = open(f, encoding="utf-8").read()
    except Exception: continue
    for link in link_re.findall(text):
        if link.startswith(("http://", "https://", "#", "mailto:")): continue
        p = link.split("#")[0]
        if not p: continue
        if not os.path.exists(os.path.normpath(os.path.join(base, p))):
            print(f"  ❌ {f}: broken link -> {link}"); broken += 1
if broken:
    print(f"  ❌ validate-links FAILED ({broken} broken across {scanned} files)"); sys.exit(1)
print(f"  ·  {scanned} markdown file(s) scanned, all relative links resolve")
print("  ✅ validate-links clean")
PYEOF
  exit $?
fi

# ---- pure-bash fallback ----
broken=0; scanned=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  scanned=$((scanned + 1))
  dir="$(dirname "$f")"
  while IFS= read -r link; do
    [ -z "$link" ] && continue
    case "$link" in http://*|https://*|\#*|mailto:*) continue ;; esac
    target="${link%%#*}"
    [ -z "$target" ] && continue
    [ -e "$dir/$target" ] || { printf '  ❌ %s: broken link -> %s\n' "$f" "$link"; broken=$((broken + 1)); }
  done <<INNER
$(grep -oE '\]\([^)]+\)' "$f" | sed -E 's/^\]\(//; s/\)$//')
INNER
done <<EOF
$(find . -type f -name '*.md' -not -path './.git/*' | sort)
EOF

if [ "$broken" -gt 0 ]; then
  printf '  ❌ validate-links FAILED (%d broken across %d files)\n' "$broken" "$scanned"
  exit 1
fi
printf '  ·  %d markdown file(s) scanned, all relative links resolve\n' "$scanned"
printf '  ✅ validate-links clean\n'
exit 0
