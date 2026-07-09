# Contributing to Thekedar

Shukriya for considering it! 🏗️

## Ground rules

1. **Zero-dependency law.** PRs adding npm/pip runtime dependencies will be closed with love. Markdown + bash + git only. (`jq`/`python3` may be *used if present*, never *required*.)
2. **Three hooks never block; two guards block only on a confirmed hit.** `munshi.sh`, `session-brief.sh`, and `drift-check.sh` must keep the always-`exit 0` guarantee. `scope-guard.sh` and `secret-guard.sh` may `exit 2`, but every parse failure, missing dependency, or internal doubt must still fail open (`exit 0`) — see [ADR-0002](docs/adr/0002-hooks-never-block-except-guards.md). Any change to a hook must pass its fixture suite in `tests/`, including both the block path and every fail-open path.
3. **Formats are contracts.** Changes to task / PROJECT_STATE / changelog / config templates, or hook I/O, are breaking changes → need a TRD §3 update in the same PR, plus a version-bump discussion.
4. **Gates stay read-only.** Any new reviewer/auditor agent gets `tools: Read, Grep, Glob, Bash` — never Write/Edit. `scripts/doctor.sh` checks this mechanically; a PR that fails it will not merge.
5. **Dogfood.** If you change the workflow, use Thekedar itself to make the change and attach the generated `changes/task-*.md` to your PR. Best PR description format ever.
6. **shellcheck clean.** Every `*.sh` file must pass `shellcheck` (CI enforces this — see `.github/workflows/shellcheck.yml`). Fix the code, don't blanket-suppress; a targeted `# shellcheck disable=SCxxxx` with a one-line reason is fine for genuine false positives only.

## Dev setup

```bash
git clone https://github.com/soumyachk101/Thekedar && cd Thekedar

# full test suite (7 suites, must all pass):
bash tests/run-all.sh

# shellcheck (must be clean):
shellcheck ./*.sh hooks/*.sh scripts/*.sh tests/*.sh

# installer test in a scratch repo:
mkdir /tmp/scratch && cd /tmp/scratch && git init -q
bash /path/to/thekedar/install.sh --full
bash /path/to/thekedar/install.sh --full   # re-run: must be idempotent
bash .thekedar/scripts/doctor.sh            # should be all-green
```

## What we'd love help with

- Prompt tuning for the crew (with before/after examples of real reviews — see the PR template's evidence requirement)
- F14: Claude Code plugin marketplace packaging
- F15: Agent Teams mode (parallel independent tasks, once the feature leaves experimental)
- Windows-native (PowerShell) hook variants — currently Git Bash / WSL only
- The Mega specialist-catalog expansion (see MEGA_EXPANSION.md) — a separate, later scale-up track
- Real benchmark runs against the methodology in [docs/BENCHMARKS.md](docs/BENCHMARKS.md) — no numbers are published yet; a reproducible run is a genuinely valuable contribution
- Real-world reports: where did the workflow save you / annoy you?

## PR checklist

- [ ] Hook fixture tests pass (if any `hooks/*.sh` touched) — `bash tests/run-all.sh`
- [ ] Installer idempotency verified (if `install.sh`/`uninstall.sh`/`update.sh` touched)
- [ ] Docs updated (README/TRD/relevant guide in `docs/`) if behavior changed
- [ ] No new runtime dependencies
- [ ] shellcheck clean on every touched `*.sh`
- [ ] Gates still carry no Write/Edit (if any agent file touched) — `bash scripts/doctor.sh` if you have a scratch install handy

## Agent prompt changes

Subagent prompts (`.claude/agents/{core,extended}/*.md`) are the product. For prompt PRs, include: the failure you saw, the prompt change, and one transcript snippet showing the improvement. "Feels better" isn't reviewable; evidence is. Use the **Agent / prompt improvement** issue template as your starting structure.

## Adding a new specialist agent

Prefer proposing it as an issue first (what gap it fills, why an existing agent can't cover it) before writing the PR — the crew is easy to grow but hard to prune once merged. Use `scripts/new-agent.sh` to scaffold it correctly (tool allowlist pre-applied), then write the actual prompt by hand; the scaffold is a starting frame, not a finished agent.

## Conduct

Be the kind of contributor a good thekedar would hire: direct, respectful, shows their work. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for the formal version.
