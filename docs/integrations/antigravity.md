# Thekedar for Antigravity

Antigravity support uses Thekedar's portable `AGENTS.md` mode.

From your project root:

```bash
git clone https://github.com/soumyachk101/Thekedar /tmp/thekedar
bash /tmp/thekedar/scripts/install-antigravity.sh          # core crew
bash /tmp/thekedar/scripts/install-antigravity.sh --full   # core + extended crew
bash /tmp/thekedar/scripts/install-antigravity.sh --all    # whole catalog
```

This writes:

- `AGENTS.md` with the Thekedar plan -> build -> review -> log workflow
- `.thekedar/` state, templates, scripts, and knowledge packs

Then reopen or restart the project in Antigravity so the agent reloads project instructions. Ask for work normally, for example:

```text
Build this feature using the Thekedar workflow.
```

## Known limitation

There is no verified public Antigravity plugin or hook manifest format in this repository yet. This adapter deliberately sticks to the portable `AGENTS.md` contract, so it produces the same task files, changelogs, and project state, but does not provide mechanical PreToolUse guard hooks or fresh subagent isolation.
