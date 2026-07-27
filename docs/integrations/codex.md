# Thekedar for Codex

Codex has two supported paths.

## Plugin install

```bash
codex plugin marketplace add soumyachk101/Thekedar
codex plugin add thekedar@thekedar
```

Then start a new Codex session in your project. Use `$thekedar`, `$thekedar-plan`, `$thekedar-status`, or `$thekedar-report`.

The plugin bundles the same four skills and hook scripts as the Claude Code release. On first session, the SessionStart hook creates `.thekedar/` scaffolding in the target project.

## Repo-local install

From your project root:

```bash
git clone https://github.com/soumyachk101/Thekedar /tmp/thekedar
bash /tmp/thekedar/scripts/install-codex.sh          # core crew in AGENTS.md
bash /tmp/thekedar/scripts/install-codex.sh --full   # core + extended crew
bash /tmp/thekedar/scripts/install-codex.sh --all    # whole catalog
```

This writes:

- `.agents/skills/thekedar*/SKILL.md` for native Codex skill discovery
- `.codex/hooks.json` and `.codex/hooks/*.sh` for project hooks
- `AGENTS.md` as a portable single-context fallback
- `.thekedar/` state, templates, scripts, and knowledge packs

Restart Codex after installing. Run `bash .thekedar/scripts/doctor.sh` to verify the shared project state.

## Known limitation

Codex custom agents use TOML configuration, while Thekedar's full 109-agent catalog is still authored in Claude-style markdown agent files. Today the Codex path exposes the workflow through skills, hooks, and `AGENTS.md`; the portable `AGENTS.md` mode is weaker than fresh isolated subagents because one context plays every role in sequence.
