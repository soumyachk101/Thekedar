#!/usr/bin/env bash
# ============================================================
#  Thekedar updater
#  Usage, from your project root:
#    bash /path/to/thekedar/update.sh [--full]
#
#  Pulls the latest thekedar source, then re-runs install.sh
#  into the current project. install.sh's backup-on-difference
#  rule protects any local edits (they land in *.bak).
# ============================================================
set -u

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
say() { printf '  %s\n' "$*"; }

printf '\n\033[1m🏗️  Thekedar updater\033[0m\n'

if command -v git >/dev/null 2>&1 && [ -d "$SRC/.git" ]; then
  BEFORE="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo '?')"
  if git -C "$SRC" pull --ff-only 2>/dev/null; then
    AFTER="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo '?')"
    if [ "$BEFORE" = "$AFTER" ]; then
      say "source : already up to date ($AFTER)"
    else
      say "source : updated $BEFORE → $AFTER"
    fi
  else
    say "⚠️  git pull failed (offline? diverged?) — installing from the source as-is."
  fi
else
  say "⚠️  $SRC is not a git clone — installing from the source as-is."
fi

exec bash "$SRC/install.sh" "$@"
