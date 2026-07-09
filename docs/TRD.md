# TRD — Thekedar

**Technical Requirements Document**
Version 1.0 · July 2026 · Companion to [PRD.md](PRD.md)

---

## 1. Design Principles

1. **Markdown is the interface.** Agents, skill, tasks, state, changelogs — all `.md`. Humans and models read the same files.
2. **Zero runtime dependencies.** `bash` + `git`; `jq`/`python3` optional for the hook. No npm install, no daemon.
3. **Deterministic where possible, LLM where necessary.** The ledger (facts) is a bash hook. The changelog (reasoning) is the model. Never pay tokens for what a script can do.
4. **Never block the user.** The munshi hook exits 0 unconditionally. A logging failure must never break a coding session.
5. **Git-native.** State is files; checkpoints are commits; rollback is `git revert`. No custom persistence layer.
6. **Fail toward less magic.** If anything is missing (template, dir, jq), degrade gracefully and tell the user in plain text.

## 2. Platform & Compatibility

| Target | Mechanism | v1 support |
|---|---|---|
| Claude Code ≥ 2.x | Subagents + Skill + PostToolUse hook | ✅ Full |
| Cursor, Codex CLI, Copilot, Windsurf, etc. | Generated `AGENTS.md` (workflow-as-rules; no subagent isolation) | 🟡 P1, degraded mode |
| OS | macOS, Linux, WSL, Git Bash | ✅ |

Degraded mode = one agent follows the same plan→build→review→log loop sequentially in one context. Weaker isolation, same paper trail.

## 3. Component Specifications

### 3.1 Directory layout (installed into a user project)

```
project/
├── .claude/
│   ├── settings.json            # hook wiring (merged, never overwritten)
│   ├── hooks/munshi.sh
│   ├── skills/thekedar/SKILL.md
│   └── agents/
│       ├── planner.md
│       ├── backend-dev.md
│       ├── error-checker.md
│       ├── security-auditor.md
│       └── frontend-reviewer.md
└── .thekedar/
    ├── PROJECT_STATE.md
    ├── templates/               # task.md, changelog-entry.md (copied at install)
    ├── tasks/                   # 001-*.md, 002-*.md ...
    └── changes/                 # ledger-YYYY-MM-DD.md + task-NNN.md
```

Rationale for `.thekedar/` vs `.claude/`: project *artifacts* (tasks, state, changelogs) are tool-agnostic and belong to the repo; `.claude/` holds only Claude-Code-specific configuration. Both are committed to git.

### 3.2 Subagent file format (verified against Claude Code docs)

Subagents are markdown files with YAML frontmatter in `.claude/agents/` (project scope) or `~/.claude/agents/` (user scope). Project scope wins on name collision. Frontmatter fields used:

```yaml
---
name: error-checker            # unique id; how the orchestrator invokes it
description: >                 # DRIVES AUTO-DELEGATION — written as a trigger
  MUST BE USED after any code implementation task...
tools: Read, Bash, Grep, Glob  # allowlist; reviewers get NO Write/Edit
model: sonnet                  # sonnet | haiku | opus | inherit
---
(markdown body = the agent's system prompt, verbatim)
```

Constraints:

- **Reviewers are read-only**: `tools` excludes Write/Edit/MultiEdit. This is enforced by Claude Code's tool allowlist, not by prompt hope.
- The main session needs the `Task` tool available to spawn subagents (default in Claude Code).
- Subagent files are loaded at session start; editing a file on disk requires a session restart to take effect.
- Each subagent runs in a **fresh, isolated context** and returns only its report — file dumps and test logs never pollute the main conversation.

### 3.3 Model routing (token budget)

| Agent | Model | Why |
|---|---|---|
| main session / orchestrator | user's choice (Opus recommended) | judgment & coordination |
| planner | inherit | planning quality matters most |
| backend-dev | sonnet | implementation workhorse, cost-efficient |
| error-checker | sonnet | must reason about failures |
| security-auditor | sonnet | pattern + reasoning |
| frontend-reviewer | sonnet | code review depth |
| munshi | — (bash) | facts are free |

Estimated overhead vs raw single session: 2–4× tokens on orchestrated work. Reviewers fire **once per task**, not per edit — this is the primary cost control.

### 3.4 Munshi hook (deterministic ledger)

**Trigger:** `PostToolUse` with matcher `Write|Edit|MultiEdit` in `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/munshi.sh\""
          }
        ]
      }
    ]
  }
}
```

**Input protocol (verified):** Claude Code passes event JSON on **stdin**. Relevant fields: `session_id`, `cwd`, `hook_event_name`, `tool_name`, `tool_input` (contains `file_path`), `tool_response`. `$CLAUDE_PROJECT_DIR` is available in the environment.

**Behavior:**

1. Read stdin JSON. Parse `tool_name` + `tool_input.file_path` via `jq`, falling back to `python3`, falling back to a grep heuristic.
2. Append one line to `.thekedar/changes/ledger-$(date +%F).md`:
   `| HH:MM:SS | Edit | src/auth/login.ts |`
3. Create the ledger file with a header table if absent.
4. **Always `exit 0`.** All failure paths swallowed (`2>/dev/null || true`). Exit code 2 semantics (blocking) are deliberately never used.

**Performance budget:** < 50 ms per invocation (pure bash + one append). Hooks run synchronously; anything slower degrades every edit.

### 3.5 Orchestrator skill

`.claude/skills/thekedar/SKILL.md`. Progressive disclosure: only `name` + `description` load at session start; full body loads when triggered. Description must therefore carry the triggers ("build/plan a project", "continue", "/thekedar").

The skill encodes the **state machine**:

```
IDLE → PLANNING → TASK_ACTIVE → REVIEW → (PASS → LOG+COMMIT → next | FAIL → FIX loop, max 3) → DONE
```

Hard rules the skill enforces (see SKILL.md for exact text):

- Never start coding a multi-step request without task files existing.
- Exactly one task in `ACTIVE` state at a time.
- A task is complete only when: acceptance criteria met AND error-checker PASS AND security-auditor PASS (frontend-reviewer PASS when UI files touched).
- After completion: write `changes/task-NNN.md`, update `PROJECT_STATE.md`, `git commit`.
- Fix loop cap: 3 attempts, then stop and escalate to the human with the reviewer report.
- Trivial-request exemption: single-file, < ~30-line asks skip the ceremony entirely.

### 3.6 File format contracts

> v2.0.0 format revision. Any further change to these contracts = major version bump (see §7).

**Task file** (`tasks/NNN-slug.md`) — see `templates/task.md`. Required sections: Objective, In scope, **NOT in scope**, Acceptance criteria (checkboxes), Expected files, Depends on, Status (`TODO|ACTIVE|REVIEW|DONE|BLOCKED`), Risk (`low|medium|high`), Estimated size (`S|M|L`). Optional: `## Scope addition` entries appended by the doer (file + one-line reason) — read by scope-guard.sh and drift-check.sh.

**PROJECT_STATE.md** — Required sections: Project overview (3 lines max), Current phase, Phases (optional, big projects: one line per phase), Active task, Done, Up next, Decisions log (append-only), Known issues. Contract: any fresh session must be able to resume from this file alone (session-brief.sh injects it at SessionStart).

**Changelog entry** (`changes/task-NNN.md`) — Required sections: What changed, What was deliberately NOT changed, Why, Files touched, Verification (reviewer verdicts + test summary + verbatim drift-check line), Follow-ups.

**Phase file** (`templates/phase.md`, big projects) — Status (`planned|building|done`), Goal, Task list, Exit criteria.

**Decision record** (`templates/decision-record.md`) — ADR format: Context, Decision, Consequences, Alternatives considered.

**Agent template** (`templates/agent-template.md`) — scaffold for `scripts/new-agent.sh`; placeholders `{{NAME}}`, `{{TRIGGER}}`, `{{TOOLS}}`, `{{MODEL}}`, `{{ROLE}}`. Frontmatter law: doers get `Read, Write, Edit, Bash, Grep, Glob`; gates get `Read, Grep, Glob, Bash` (no Write/Edit).

**Config** (`.thekedar/config.md`, from `templates/config.md`) — plain `key: value` lines, `#` starts a comment, missing key = default. Keys: `fix_loop_cap` (3), `auto_continue` (true), `default_doer_model` (sonnet), `enable_performance_auditor` (false), `enable_accessibility_auditor` (false), `scope_guard` (on|off — off = advisory), `commit_prefix` ("thekedar"). Consumers: the orchestrator skill (loop cap, models, auditor opt-ins, commit prefix) and scope-guard.sh (`scope_guard` key only).

### 3.7 Installer (`install.sh`)

1. Detect project root (must contain `.git`, else warn and proceed).
2. `mkdir -p` all target dirs; copy agents, skill, hook, templates. Never overwrite user-modified files without `--force`; back up as `*.bak`.
3. **Merge** hook config into `.claude/settings.json` via `python3` JSON merge (preserves existing hooks); if no `python3`, print the JSON block for manual paste.
4. `chmod +x` munshi.sh; initialize `.thekedar/PROJECT_STATE.md` from template if absent.
5. Print verification steps + "restart your Claude Code session".

Idempotent: safe to re-run.

## 4. Task Lifecycle (data flow)

```
user request
  → skill triggers → planner subagent (fresh ctx)
      reads codebase (Read/Grep/Glob) → writes tasks/*.md + PROJECT_STATE
  → orchestrator marks 001 ACTIVE
  → backend-dev subagent (fresh ctx): input = task file + only relevant paths
      implements → each Write/Edit fires munshi → ledger line appended
  → orchestrator spawns reviewers (parallel, fresh ctx each, read-only)
      error-checker: runs tests → report {PASS|FAIL, findings[severity]}
      security-auditor: scans diff → report
      frontend-reviewer: (conditional) → report
  → all PASS?
      yes → orchestrator writes changes/task-001.md, updates STATE,
            git add -A && git commit -m "thekedar(task-001): <title>"
      no  → backend-dev re-invoked with reviewer findings (≤3 loops)
  → next TODO task, or DONE summary to user
```

## 5. Security Considerations

- Hook script executes with user privileges: keep it auditable (~60 lines), no network calls, no eval of stdin content, paths quoted.
- security-auditor checklist includes: hardcoded secrets/keys, injection (SQL/command/XSS), authz gaps on new endpoints, unsafe deserialization, dependency red flags. It reads; it never fixes (report-only).
- Installer never touches files outside the project dir and `~/.claude` is opt-in only.
- Recommend `.thekedar/` committed (audit trail) — contains no secrets by design; ledger stores paths, not content.

## 6. Testing Plan

- **Hook unit tests:** pipe fixture JSON into munshi.sh (`echo '{"tool_name":"Edit","tool_input":{"file_path":"a.ts"}}' | bash munshi.sh`); assert ledger line, assert exit 0 on malformed input, missing jq, read-only fs.
- **Installer test:** fresh temp git repo → install → assert tree, settings merge idempotency, re-run safety.
- **Golden-path e2e (manual, per release):** demo todo-app repo; script the request; verify tasks created, reviewers invoked, ledger + changelogs + commits present; fresh-session resume works.
- **Format drift CI (P1):** weekly job fetches Claude Code docs pages and diffs the frontmatter/hook schema sections against pinned copies; open issue on drift.

## 7. Versioning & Releases

- SemVer. Breaking = any change to task/state/changelog file contracts or hook I/O.
- CHANGELOG.md maintained by… Thekedar itself (dogfooding).
- Release artifacts: git tag + zip. P2: Claude Code plugin marketplace packaging.

## 8. Open Questions

1. Should the fix-loop cap (3) be configurable via a `.thekedar/config.md`? (leaning yes, P1)
2. Ledger rotation: daily files forever, or monthly roll-up? (v1: daily, revisit at scale)
3. Windows PowerShell-native hook variant, or document Git Bash as requirement? (v1: Git Bash)
