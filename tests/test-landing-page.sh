#!/usr/bin/env bash
# test-landing-page.sh — guards on index.html that fail SILENTLY in a browser.
#
# The landing page is 1700 lines of hand-edited HTML with no build step, and
# every bug found in it so far was invisible rather than broken-looking:
#   · `overflow-x: hidden` on html/body turned them into scroll containers,
#     which killed `position: sticky` — the navbar simply scrolled away, with
#     no error anywhere.
#   · icons marked aria-hidden inside icon-only links left those links with no
#     accessible name at all.
#   · `user-scalable=no` blocked pinch-zoom (WCAG 1.4.4).
# None of these throw. Grep is enough to catch all of them, and grep needs no
# browser, no node, and no network — so it can live in this suite.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PAGE="$ROOT/index.html"

fails=0
pass() { printf '     ok: %s\n' "$1"; }
fail() { printf '   FAIL: %s\n' "$1"; fails=$((fails + 1)); }
has()  { if grep -q "$2" "$PAGE"; then pass "$1"; else fail "$1"; fi; }
hasnt(){ if grep -q "$2" "$PAGE"; then fail "$1"; else pass "$1"; fi; }

[ -f "$PAGE" ] || { printf '   FAIL: index.html missing\n'; exit 1; }

# ---- sticky navbar ----
# `clip` must WIN, so it has to come after `hidden` in the same rule.
if awk '/^[[:space:]]*(html|body)[[:space:]]*\{/,/\}/' "$PAGE" | grep -q 'overflow-x: clip'; then
  pass "html/body use overflow-x: clip (position: sticky survives)"
else
  fail "html/body missing overflow-x: clip — 'hidden' alone breaks the sticky navbar"
fi
n_hidden=$(awk '/^[[:space:]]*(html|body)[[:space:]]*\{/,/\}/' "$PAGE" | grep -c 'overflow-x: hidden')
n_clip=$(awk '/^[[:space:]]*(html|body)[[:space:]]*\{/,/\}/' "$PAGE" | grep -c 'overflow-x: clip')
if [ "$n_clip" -ge "$n_hidden" ]; then
  pass "every overflow-x: hidden on html/body is followed by a clip override"
else
  fail "an overflow-x: hidden on html/body has no clip override ($n_hidden hidden, $n_clip clip)"
fi
has "header is position: sticky" 'position: sticky'

# ---- nav collapse breakpoint ----
# The desktop nav lays out at 1153px and needs a ~1177px viewport. Collapsing it
# at the phone breakpoint left 769-1177px overflowing off-screen. The collapse
# must therefore live in a media query of at least 1180px, not in the 768 block.
bp=$(grep -B2 '\.nav-menu { display: none; }' "$PAGE" \
     | grep -o 'max-width: [0-9]*px' | grep -o '[0-9]*' | sort -rn | head -1)
if [ -n "$bp" ] && [ "$bp" -ge 1180 ]; then
  pass "desktop nav collapses at ${bp}px (>= 1180px, so it never overflows)"
else
  fail "desktop nav collapses at ${bp:-?}px — below 1180px the navbar overflows off-screen"
fi

# Collapsing the desktop nav is only safe if the drawer carries every link.
missing=0
while IFS= read -r h; do
  [ -n "$h" ] || continue
  grep -q "href=\"$h\" class=\"mobile-nav-link\"" "$PAGE" || missing=$((missing + 1))
done <<EOF
$(grep -o 'href="#[a-z]*" class="nav-link"' "$PAGE" | sed 's/href="//; s/".*//')
EOF
if [ "$missing" -eq 0 ]; then pass "mobile drawer carries every desktop nav link"
else fail "$missing desktop nav link(s) have no drawer equivalent — unreachable once collapsed"; fi

# ---- scroll-spy ----
has "nav has an .active style to apply"        '\.nav-link\.active'
has "scroll-spy observer is wired"             'IntersectionObserver'
has "active link exposes aria-current"         "aria-current"

# ---- accessibility ----
hasnt "viewport does not block pinch-zoom"     'user-scalable=no'
hasnt "viewport does not cap max scale"        'maximum-scale'
has   "reduced-motion is respected"            'prefers-reduced-motion'

n=$(grep -o '<i class="fa-[^>]*>' "$PAGE" | grep -vc 'aria-hidden' || true)
if [ "$n" -eq 0 ]; then pass "every decorative icon is aria-hidden"
else fail "$n decorative icon(s) missing aria-hidden"; fi

# An <a>/<button> whose only content is an aria-hidden icon has NO accessible
# name. That is worse than leaving the icon exposed, so it must be caught.
if command -v python3 >/dev/null 2>&1; then
  n=$(python3 - "$PAGE" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
bad = 0
for m in re.finditer(r'<(a|button)\b([^>]*)>(.*?)</\1>', s, re.S):
    attrs, inner = m.group(2), m.group(3)
    if 'aria-label' in attrs:
        continue
    if not re.sub(r'<[^>]+>', '', inner).strip():
        bad += 1
print(bad)
PY
)
  if [ "$n" -eq 0 ]; then pass "no icon-only control left without an accessible name"
  else fail "$n icon-only control(s) have no accessible name"; fi
else
  printf '     ·  python3 absent — skipping accessible-name scan\n'
fi

# ---- external links ----
n_blank=$(grep -c 'target="_blank"' "$PAGE" || true)
n_rel=$(grep -c 'rel="noopener' "$PAGE" || true)
if [ "$n_rel" -ge "$n_blank" ]; then pass "every target=_blank carries rel=noopener"
else fail "$((n_blank - n_rel)) target=_blank link(s) missing rel=noopener"; fi

# ---- social preview ----
for meta in 'og:image' 'og:title' 'twitter:card' 'rel="canonical"' 'application/ld+json'; do
  has "social/SEO meta present: $meta" "$meta"
done
if [ -f "$ROOT/assets/og-image.jpg" ]; then pass "og:image asset exists on disk"
else fail "og:image points at a missing file"; fi

# ---- docs deep-linking ----
has "docs are hash-routed (deep-linkable)" 'href="#doc-'
n=$(grep -o 'href="#doc-[a-z0-9-]*"' "$PAGE" | sed 's/.*#doc-//; s/"//' | sort -u | wc -l | tr -d ' ')
d=0
while IFS= read -r k; do
  [ -n "$k" ] || continue
  # docsData mixes quoted and bare keys — hyphenated ones must be quoted,
  # plain identifiers ('overview') need not be. Accept either.
  grep -qE "(^|[{,[:space:]])'?${k}'?[[:space:]]*:" "$PAGE" || d=$((d + 1))
done <<EOF
$(grep -o 'href="#doc-[a-z0-9-]*"' "$PAGE" | sed 's/.*#doc-//; s/"//' | sort -u)
EOF
if [ "$d" -eq 0 ]; then pass "all $n doc hash routes resolve to a real doc"
else fail "$d doc hash route(s) point at a doc that does not exist"; fi

exit "$fails"
