# Contributing to Thekedar

Shukriya for considering it! 🏗️

## Ground rules

1. **Zero-dependency law.** PRs adding npm/pip runtime dependencies will be closed with love. Markdown + bash + git only. (`jq`/`python3` may be *used if present*, never *required*.)
2. **Munshi never blocks.** Any change to `hooks/munshi.sh` must keep the always-`exit 0` guarantee and pass the fixture tests below.
3. **Formats are contracts.** Changes to task / PROJECT_STATE / changelog templates or hook I/O are breaking changes → need a TRD update + version bump discussion first.
4. **Dogfood.** If you change the workflow, use Thekedar itself to make the change and attach the generated `changes/task-*.md` to your PR. Best PR description format ever.

## Dev setup

```bash
git clone https://github.com/YOUR_USERNAME/thekedar && cd thekedar

# hook fixture tests (must all print exit=0):
echo '{"tool_name":"Edit","tool_input":{"file_path":"a.ts"}}' | CLAUDE_PROJECT_DIR=/tmp/t bash hooks/munshi.sh; echo exit=$?
echo 'garbage {{{'                                            | CLAUDE_PROJECT_DIR=/tmp/t bash hooks/munshi.sh; echo exit=$?
printf ''                                                     | CLAUDE_PROJECT_DIR=/tmp/t bash hooks/munshi.sh; echo exit=$?

# installer test in a scratch repo:
mkdir /tmp/scratch && cd /tmp/scratch && git init -q && bash /path/to/thekedar/install.sh
bash /path/to/thekedar/install.sh   # re-run: must be idempotent
```

## What we'd love help with

- Prompt tuning for the crew (with before/after examples of real reviews)
- F10: AGENTS.md export for Cursor/Codex/Copilot users
- The drift detector (F12) — small script, big value
- Windows-native (PowerShell) munshi variant
- Real-world reports: where did the workflow save you / annoy you?

## PR checklist

- [ ] Hook fixture tests pass (if hook touched)
- [ ] Installer idempotency verified (if installer touched)
- [ ] Docs updated (README/TRD) if behavior changed
- [ ] No new runtime dependencies

## Agent prompt changes

Subagent prompts (`.claude/agents/*.md`) are the product. For prompt PRs, include: the failure you saw, the prompt change, and one transcript snippet showing the improvement. "Feels better" isn't reviewable; evidence is.

## Conduct

Be the kind of contributor a good thekedar would hire: direct, respectful, shows their work.
