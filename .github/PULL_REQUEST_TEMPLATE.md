## What & why

<One or two sentences. What changed, and the reason — not just the mechanics.>

## Type

- [ ] Fix
- [ ] Feature
- [ ] Docs
- [ ] Prompt tuning (`.claude/agents/*.md`, skills)
- [ ] Refactor / chore

## Dogfood rule (CONTRIBUTING.md #4)

If this PR changes the workflow itself, you built it USING Thekedar. Attach the generated changelog:

<!-- paste the contents of .thekedar/changes/task-NNN.md here, or link it -->

## Checklist

- [ ] Hook fixture tests pass (if `hooks/*.sh` touched) — `bash tests/run-all.sh`
- [ ] Installer idempotency verified (if `install.sh`/`uninstall.sh`/`update.sh` touched)
- [ ] Docs updated (README/TRD/relevant guide) if behavior changed
- [ ] No new runtime dependencies
- [ ] shellcheck clean (if any `*.sh` touched)

## For agent prompt changes (`.claude/agents/*.md`)

- **Failure observed:** <what went wrong before this change>
- **Prompt change:** <what you changed>
- **Evidence:** <a transcript snippet showing the improvement — "feels better" isn't reviewable>
