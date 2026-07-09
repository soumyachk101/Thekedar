# Installing Thekedar

## Requirements

- **Claude Code ≥ 2.x** (primary target)
- `bash`, `git`
- `jq` **or** `python3` (recommended — the munshi hook uses them to parse events; it degrades gracefully without them)
- OS: macOS, Linux, WSL, Git Bash on Windows

## Quick install (Claude Code)

From **your project root**:

```bash
git clone https://github.com/soumyachk101/Thekedar /tmp/thekedar
bash /tmp/thekedar/install.sh
```

Then **restart your Claude Code session** — subagents and skills load at session start.

## What the installer does

1. Copies 5 subagents → `.claude/agents/`
2. Copies the orchestrator skill → `.claude/skills/thekedar/SKILL.md`
3. Copies the munshi hook → `.claude/hooks/munshi.sh` (`chmod +x`)
4. **Merges** the hook wiring into `.claude/settings.json` — your existing hooks and settings are preserved; a differing file is backed up to `*.bak`
5. Creates `.thekedar/` (tasks, changes, templates) and initializes `PROJECT_STATE.md`

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

## Other tools (Cursor, Codex, Copilot, ...)

v1 is Claude-Code-first. A degraded single-context mode via the **AGENTS.md standard** is on the [roadmap](ROADMAP.md) (F10): the same plan→build→review→log loop as sequential rules, same files on disk — just without subagent isolation.

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
