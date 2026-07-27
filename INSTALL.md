# Installing Thekedar

## Requirements

- **Claude Code ≥ 2.x** or **Codex** for full skills/hooks mode
- Any `AGENTS.md`-aware coding agent for portable mode (Antigravity, Cursor, Copilot, Windsurf, ...)
- `bash`, `git`
- `jq` **or** `python3` (recommended — the munshi hook uses them to parse events; it degrades gracefully without them)
- OS: macOS, Linux, WSL, Git Bash on Windows

## Install matrix

| Target | Command | What lands in your repo | Best for |
|---|---|---|---|
| Claude Code plugin | `claude plugin marketplace add …` + `claude plugin install …` | `.thekedar/` scaffolding on first session | trying it, personal use, auto-updates |
| Codex plugin | `codex plugin marketplace add …` + `codex plugin add …` | `.thekedar/` scaffolding on first session | native Codex skills/hooks |
| Claude Code repo install | `bash install.sh [--full|--all]` | `.claude/` + `.thekedar/` | teams using Claude Code |
| Codex repo install | `bash scripts/install-codex.sh [--full|--all]` | `.agents/skills/` + `.codex/` + `AGENTS.md` + `.thekedar/` | teams using Codex |
| Antigravity portable install | `bash scripts/install-antigravity.sh [--full|--all]` | `AGENTS.md` + `.thekedar/` | AGENTS.md-only workflow |

All paths draw from the same 109-agent catalog ([catalog/INDEX.md](catalog/INDEX.md)), 5 hooks, and 4 skills where the target supports them. Pick one hook-bearing path per project — running both Claude and Codex hook installs against one repo can double-log edits.

## Option A — Plugin (Claude Code marketplace)

```bash
claude plugin marketplace add soumyachk101/Thekedar
claude plugin install thekedar@thekedar
```

On your next session in any project, the plugin's SessionStart hook creates the `.thekedar/` scaffolding (tasks/, changes/, templates/, scripts/, PROJECT_STATE.md, config.md) automatically, then the crew is ready. Say *"build me &lt;something&gt;"* or `/thekedar-plan`.

## Option B — Plugin (Codex)

```bash
codex plugin marketplace add soumyachk101/Thekedar
codex plugin add thekedar@thekedar
```

Start a new Codex session after installing. Use `$thekedar`, `$thekedar-plan`, `$thekedar-status`, or `$thekedar-report`. See [docs/integrations/codex.md](docs/integrations/codex.md).

## Option C — Claude Code script install

From **your project root**:

```bash
git clone https://github.com/soumyachk101/Thekedar /tmp/thekedar
bash /tmp/thekedar/install.sh          # core crew (6 agents)
bash /tmp/thekedar/install.sh --full   # + 9 extended specialists (15 total)
bash /tmp/thekedar/install.sh --all    # the whole catalog (109 agents)
```

Then **restart your Claude Code session** — subagents and skills load at session start.

## Option D — Codex repo install

From **your project root**:

```bash
git clone https://github.com/soumyachk101/Thekedar /tmp/thekedar
bash /tmp/thekedar/scripts/install-codex.sh          # core crew in AGENTS.md
bash /tmp/thekedar/scripts/install-codex.sh --full   # core + extended crew
bash /tmp/thekedar/scripts/install-codex.sh --all    # whole catalog
```

Then restart Codex. This installs native repo skills under `.agents/skills`, project hooks under `.codex/`, and `AGENTS.md` as a fallback.

## Option E — Antigravity / portable AGENTS.md install

From **your project root**:

```bash
git clone https://github.com/soumyachk101/Thekedar /tmp/thekedar
bash /tmp/thekedar/scripts/install-antigravity.sh --all
```

Then reopen the project in Antigravity so it reloads `AGENTS.md`. See [docs/integrations/antigravity.md](docs/integrations/antigravity.md).

## What the installer does

1. Copies the selected subagents → `.claude/agents/<category>/` (roster read from `catalog/agents.psv`)
2. Copies the orchestrator skill → `.claude/skills/thekedar/SKILL.md`
3. Copies the munshi hook → `.claude/hooks/munshi.sh` (`chmod +x`)
4. **Merges** the hook wiring into `.claude/settings.json` — your existing hooks and settings are preserved; a differing file is backed up to `*.bak`
5. Creates `.thekedar/` (tasks, changes, templates) and initializes `PROJECT_STATE.md`
6. Copies the knowledge packs → `.thekedar/knowledge/` — the crew's shared brain. Agents cite these by path (`.thekedar/knowledge/pitfalls/react.md`), so they ship on every install regardless of `--full`/`--all`. Plugin installs get the same packs at the same path via the SessionStart bootstrap.

Idempotent — re-run anytime, including after pulling a new Thekedar version.

## Verify

```bash
# 1. Hook works and never blocks:
echo '{"tool_name":"Edit","tool_input":{"file_path":"x.ts"}}' \
  | bash .claude/hooks/munshi.sh && echo "exit ok"
cat .thekedar/changes/ledger-*.md

# 2. In a NEW Claude Code session:
#    - /hooks should list munshi under PostToolUse
#    - ask: "what subagents do you have?" → the crew of 5 appears
#    - say: "build me a small demo feature" → planner runs first
```

## Manual install

It's all just files — copy them yourself if you prefer:

| From (this repo) | To (your project) |
|---|---|
| `.claude/agents/*.md` | `.claude/agents/` |
| `skills/thekedar/SKILL.md` | `.claude/skills/thekedar/SKILL.md` |
| `hooks/munshi.sh` | `.claude/hooks/munshi.sh` (make executable) |
| `templates/*` | `.thekedar/templates/` |
| `templates/PROJECT_STATE.md` | `.thekedar/PROJECT_STATE.md` |

Then add to `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          { "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/munshi.sh\"" }
        ]
      }
    ]
  }
}
```

## Team setup

Commit `.claude/` and `.thekedar/` to the repo. Every teammate's Claude Code picks up the same crew, same workflow, same records. The changelog directory doubles as async standup notes.

## Other tools (Cursor, Copilot, Windsurf, ...)

Use `bash .thekedar/scripts/export-agents-md.sh` after a Claude/Codex repo install, or run `scripts/install-antigravity.sh` directly. This gives the same plan→build→review→log loop as sequential rules, same files on disk — just without subagent isolation or mechanical hook enforcement.

## Uninstall

```bash
rm -rf .claude/agents/{planner,backend-dev,error-checker,security-auditor,frontend-reviewer}.md \
       .claude/skills/thekedar .claude/hooks/munshi.sh
# remove the munshi entry from .claude/settings.json hooks
# keep or delete .thekedar/ — it's your project's history
```

## Troubleshooting

- **Agents don't appear** → you didn't restart the session. Subagent files load at session start.
- **No ledger lines** → run the verify command above; check `.claude/settings.json` contains the munshi entry; check the script is executable.
- **`settings.json is not valid JSON` warning** → the installer refuses to touch a broken file; fix the JSON, re-run.
- **Windows** → use Git Bash or WSL; the hook is bash.
