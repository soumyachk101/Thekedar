# TRD — Thekedar

**Technical Requirements Document**
Version 2.0 · July 2026 · Companion to [PRD.md](PRD.md)

---

## 1. Design Principles

1. **Markdown is the interface.** Agents, skills, tasks, state, changelogs, config — all `.md`. Humans and models read the same files.
2. **Zero runtime dependencies.** `bash` + `git`; `jq`/`python3` optional for hooks and the installer's JSON merge. No npm install, no daemon.
3. **Deterministic where possible, LLM where necessary.** The ledger (facts) is a bash hook. The changelog (reasoning) is the model. Never pay tokens for what a script can do.
4. **Never block the user — except the two guards, and only on a confirmed hit.** munshi, session-brief, and drift-check exit 0 unconditionally. scope-guard and secret-guard exit 2 ONLY when they've confirmed a violation; any internal doubt, parse failure, or missing dependency makes them fail open (exit 0).
5. **Git-native.** State is files; checkpoints are commits; rollback is `git revert`. No custom persistence layer.
6. **Fail toward less magic.** If anything is missing (template, dir, jq), degrade gracefully and tell the user in plain text.

## 2. Platform & Compatibility

| Target | Mechanism | v2 support |
|---|---|---|
| Claude Code ≥ 2.x | Subagents + Skills + SessionStart/PreToolUse/PostToolUse hooks | ✅ Full |
| Cursor, Codex CLI, Copilot, Windsurf, etc. | Generated `AGENTS.md` (workflow-as-rules; no subagent isolation, no guard hooks) | ✅ Shipped (F10) |
| OS | macOS, Linux, WSL, Git Bash | ✅ |

Degraded mode (AGENTS.md) = one agent plays every role sequentially in one context, following the same plan→build→review→log loop. Weaker isolation (the reviewer role shares the doer's memory), same paper trail. The guard hooks (scope-guard, secret-guard) have no equivalent — degraded mode relies on the model reading and following the NOT-in-scope section as text, same as v1's core weakness (see PRD §2, P5).

## 3. Component Specifications

### 3.1 Directory layout (installed into a user project)

```
project/
├── .claude/
│   ├── settings.json                 # hook wiring (merged, never overwritten)
│   ├── hooks/
│   │   ├── munshi.sh                 # PostToolUse — ledger
│   │   ├── scope-guard.sh            # PreToolUse — scope fence
│   │   ├── secret-guard.sh           # PreToolUse — secret scan
│   │   ├── session-brief.sh          # SessionStart — state injection
│   │   └── drift-check.sh            # orchestrator-invoked (not a hook event)
│   ├── skills/
│   │   ├── thekedar/SKILL.md         # orchestrator
│   │   ├── thekedar-status/SKILL.md
│   │   ├── thekedar-report/SKILL.md
│   │   └── thekedar-plan/SKILL.md
│   └── agents/
│       ├── core/          # 6 agents, always installed
│       ├── extended/      # 9 agents, --full only
│       └── custom/        # user-scaffolded via new-agent.sh
└── .thekedar/
    ├── PROJECT_STATE.md
    ├── config.md                     # 7 keys, see §3.6
    ├── templates/                    # 7 templates, copied at install
    ├── scripts/                      # doctor, export-agents-md, new-agent, report, stats
    ├── tasks/                        # 001-*.md, 002-*.md ...
    ├── phases/                       # phase-N.md, big projects only
    └── changes/                      # ledger-YYYY-MM-DD.md + task-NNN.md
```

Rationale for `.thekedar/` vs `.claude/`: project *artifacts* (tasks, state, changelogs, config) are tool-agnostic and belong to the repo; `.claude/` holds only Claude-Code-specific configuration. Both are committed to git. See [ADR-0007](adr/0007-dotthekedar-vs-dotclaude-split.md).

### 3.2 Subagent file format (verified against Claude Code docs)

Subagents are markdown files with YAML frontmatter in `.claude/agents/` (project scope, scanned recursively — `core/`, `extended/`, `custom/` subdirectories all load) or `~/.claude/agents/` (user scope). Project scope wins on name collision. Frontmatter fields used:

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

- **Reviewers/gates are read-only**: `tools` excludes Write/Edit/MultiEdit. Enforced by Claude Code's tool allowlist, not by prompt hope. `doctor.sh` verifies this mechanically on every health check.
- The main session needs the `Task` tool available to spawn subagents (default in Claude Code).
- Subagent files are loaded at session start; editing a file on disk requires a session restart to take effect.
- Each subagent runs in a **fresh, isolated context** and returns only its report — file dumps and test logs never pollute the main conversation.
- Only the `name:` field matters for identity — names must be globally unique across core/extended/custom.

### 3.3 Model routing (token budget)

| Agent | Model | Why |
|---|---|---|
| main session / orchestrator | user's choice (Opus recommended) | judgment & coordination |
| planner, api-designer | inherit | planning/contract quality matters most |
| backend-dev, frontend-dev, test-writer, db-specialist, devops-engineer, refactor-specialist | sonnet | implementation workhorses, cost-efficient |
| error-checker, security-auditor, frontend-reviewer, performance-auditor, accessibility-auditor | sonnet | must reason about failures/risk |
| docs-writer, dependency-auditor | haiku | pattern-matching tasks, lighter reasoning need |
| munshi, session-brief, drift-check | — (bash) | facts are free |
| scope-guard, secret-guard | — (bash) | enforcement is free and must be instant |

Estimated overhead vs raw single session: 2–4× tokens on orchestrated work (core crew). Extended crew (`--full`) adds routing precision, not proportional cost — most tasks still touch 2–3 specialists. Reviewers fire **once per task** (plus fix-loop re-runs), never per edit.

### 3.4 Munshi hook (deterministic ledger)

**Trigger:** `PostToolUse`, matcher `Write|Edit|MultiEdit`.

**Input protocol (verified):** Claude Code passes event JSON on **stdin**. Relevant fields: `session_id`, `cwd`, `hook_event_name`, `tool_name`, `tool_input` (contains `file_path`), `tool_response`. `$CLAUDE_PROJECT_DIR` is available in the environment.

**Behavior:** parse `tool_name` + `tool_input.file_path` (jq → python3 → grep fallback chain) → append one line to `.thekedar/changes/ledger-$(date +%F).md` → create the ledger with a header table if absent → **always `exit 0`**, every failure path swallowed with `2>/dev/null` placed BEFORE the redirect target so a failed write's own error message is silenced too.

**Performance budget:** < 50 ms per invocation. Measured: ~12 ms.

### 3.5 scope-guard.sh (the crown jewel — PreToolUse fence)

**Trigger:** `PreToolUse`, matcher `Write|Edit|MultiEdit`.

**Protocol:**

1. No `.thekedar/tasks/` directory → exit 0 (no task system, nothing to guard).
2. Parse `tool_input.file_path`, normalize to project-relative.
3. Path under `.thekedar/**` → exit 0 always (workflow state must stay writable).
4. Find the task file with `**Status:** ACTIVE` (grep across `tasks/*.md`). None found → exit 0 (trivial mode / between tasks — the guard only guards during orchestrated work).
5. Build the allowlist from that task's `## Expected files` + `## Scope addition` sections (glob entries supported, e.g. `src/auth/*.test.ts`).
6. Path matches (exact, glob, or under a listed directory) → exit 0.
7. No match:
   - `.thekedar/config.md` has `scope_guard: off` (comment-stripped, whitespace-trimmed) → **advisory mode**: log a `scope-advisory` line to today's ledger, exit 0 (never blocks).
   - Otherwise → **exit 2**, stderr: `SCOPE-GUARD: <path> is outside task NNN's declared files. Either add a "## Scope addition" entry (file + one-line reason) to the task file first, or leave this file alone.`

**Fail-open guarantee:** any parse failure, missing dependency, or internal doubt at any step → exit 0. A guard that bricks sessions is worse than no guard. See [ADR-0006](adr/0006-scope-guard-as-pretooluse.md).

**Performance budget:** < 50 ms. Measured: ~12 ms.

### 3.6 secret-guard.sh (PreToolUse secret scan)

**Trigger:** `PreToolUse`, matcher `Write|Edit|MultiEdit`.

**Scope of scan:** ONLY the content about to be written — `tool_input.content` (Write), `tool_input.new_string` (Edit), `tool_input.edits[].new_string` (MultiEdit). Never scans `old_string` (already-in-file text) or the raw event JSON, because that would false-positive on files that already contain the pattern being edited elsewhere, or on removal of a secret.

**Isolation requires jq or python3.** Neither present → exit 0 (fail open; scanning unstructured JSON risks matching the wrong field).

**Path exclusions** (fake secrets are legitimate by convention): `.thekedar/**`, `*/fixtures/**`, `*/__mocks__/**`, `*.sample`, `*.example`, `*.template`.

**Patterns (high-confidence only):** AWS `AKIA[0-9A-Z]{16}`, PEM private key header, JWT (three base64 segments), GitHub `ghp_`/`github_pat_`, Slack `xox[baprs]-`, Stripe `sk_live_`, Anthropic `sk-ant-`, Google `AIza`.

**Hit → exit 2**, stderr names the pattern class and the fix (env var + `.env.example` placeholder, or move to an excluded path if deliberately fake). **No hit, no jq/python3, or any internal failure → exit 0.**

### 3.7 session-brief.sh (SessionStart injection)

**Trigger:** `SessionStart`.

**Behavior:** print `.thekedar/PROJECT_STATE.md` (capped at 8000 bytes) + the ACTIVE task file path (if any) + the most recently modified `changes/task-*.md` path, wrapped in `=== THEKEDAR SESSION BRIEF ===` markers. Claude Code injects SessionStart stdout into the new session's context automatically — this is what makes resume zero-prompt (G4). No state file → prints nothing. **Always exit 0.**

### 3.8 drift-check.sh (orchestrator-invoked, not a hook event)

Not wired in `settings.json` — called explicitly by the orchestrator skill at §4 (LOG + CHECKPOINT), after a task passes review:

```
bash .claude/hooks/drift-check.sh .thekedar/tasks/NNN-slug.md
```

**Behavior:** `git status --porcelain` (modified + staged + untracked, project-relative) minus anything under `.thekedar/**`, checked against the same Expected-files/Scope-addition allowlist scope-guard uses. Outputs exactly one line:

```
DRIFT: none — 3 changed file(s), all within declared scope
DRIFT: 2 file(s) outside declared scope: src/a.ts, src/b.ts
DRIFT: n/a — <reason: no task file | git unavailable | not a repo>
```

This line goes **verbatim** into the changelog's Verification section. Not a gate — it never blocks; it's the honesty check that scope-guard's advisory mode and any pre-guard installs still get audited. **Always exit 0.**

### 3.9 Config (`.thekedar/config.md`)

Plain `key: value` lines; `#` starts a trailing comment; missing file or key = default.

| Key | Default | Consumer |
|---|---|---|
| `fix_loop_cap` | `3` | orchestrator §3 — max fix-loop attempts before BLOCKED |
| `auto_continue` | `true` | orchestrator §4 — auto-roll to next task vs pause |
| `default_doer_model` | `sonnet` | informational; actual model comes from agent frontmatter |
| `enable_performance_auditor` | `false` | orchestrator §3 — extra gate on every task |
| `enable_accessibility_auditor` | `false` | orchestrator §3 — extra gate on every task |
| `scope_guard` | `on` | scope-guard.sh — `off` = advisory (log, don't block) |
| `commit_prefix` | `"thekedar"` | orchestrator §4 — checkpoint commit message prefix |

### 3.10 Orchestrator skill

`.claude/skills/thekedar/SKILL.md`. Progressive disclosure: only `name` + `description` load at session start; full body loads when triggered. Description carries the triggers ("build/plan/implement/refactor", "continue", "/thekedar").

State machine: `IDLE → PLANNING → TASK_ACTIVE → REVIEW → (PASS → LOG+COMMIT → next | FAIL → FIX loop, max fix_loop_cap) → DONE`. Full annotated walkthrough: [WORKFLOW.md](WORKFLOW.md).

### 3.11 Installer family

- `install.sh [--full]`: idempotent, backup-on-difference (`*.bak`), never clobbers `PROJECT_STATE.md`/`config.md` if already present, python3 JSON-merges hook wiring (falls back to printing the block for manual paste).
- `uninstall.sh`: removes the 15 known agents + 4 skills + 5 hooks, strips exactly those entries from `settings.json` via a python3 filter, **keeps `.thekedar/`** (project history) and any user-defined `settings.json` keys.
- `update.sh [--full]`: `git pull --ff-only` the source clone, then `exec install.sh` with the same flags.

## 4. Task Lifecycle (data flow)

```
user request
  → skill triggers → planner subagent (fresh ctx)
      reads codebase + config → writes tasks/*.md (+ phases/*.md if >12 tasks)
  → orchestrator marks 001 ACTIVE
  → API-surface task? → api-designer writes "## API contract" into the task file
  → matching doer subagent (fresh ctx): input = task file + only relevant paths
      implements → each Write/Edit fires scope-guard + secret-guard (PreToolUse),
                   then munshi (PostToolUse) → ledger line appended
  → orchestrator spawns gates (parallel, fresh ctx each, read-only):
      error-checker + security-auditor always;
      frontend-reviewer / dependency-auditor / performance-auditor /
      accessibility-auditor conditionally (files touched, config, tags)
  → all PASS?
      yes → drift-check.sh run, DRIFT line captured →
            orchestrator writes changes/task-001.md, updates STATE,
            git add -A && git commit -m "<commit_prefix>(task-001): <title>"
      no  → doer re-invoked with reviewer findings (≤ fix_loop_cap loops)
  → next TODO task, or DONE summary to user
```

## 5. Security Considerations

- Every hook executes with user privileges: keep each auditable (well under 150 lines), no network calls, no eval of stdin content, all paths quoted.
- security-auditor checklist: hardcoded secrets/keys, injection (SQL/command/XSS), authz gaps on new endpoints, unsafe deserialization, dependency red flags. Read-only, report-only.
- secret-guard.sh is a second, mechanical line of defense at write-time — it catches what an agent might otherwise commit before security-auditor ever sees the diff.
- Installer never touches files outside the project dir; `~/.claude` (user-scope agents) is never written by install.sh.
- `.thekedar/` is designed to be committed (audit trail) and contains no secrets by design — the ledger stores paths, not content.

## 6. Testing Plan

- **Hook unit tests** (`tests/test-*.sh`, run via `tests/run-all.sh`): fixture-based, one suite per hook + installer + export script. Each hook suite asserts the always-exit-0 (or fail-open) guarantee under valid / malformed / empty / oversized / permission-denied inputs, plus the hook's specific enforcement behavior (block cases, allow cases, advisory mode).
- **Installer test:** fresh scratch repo → install → assert file counts, settings-merge idempotency (no duplicate wiring, no spurious `.bak` on identical rerun), user-setting preservation, `--full` delta, self-install refusal, uninstall (crew removed, `.thekedar/` and user settings kept).
- **doctor.sh** doubles as a manual/CI smoke test: LIVE-invokes each hook with a fixture event and checks its exit code, beyond just checking files exist.
- **Golden-path e2e (manual, per release):** demo project; script the request; verify tasks created, reviewers invoked, ledger + changelogs + commits present; fresh-session resume works via session-brief.
- **CI (Phase 8):** `tests/run-all.sh` on ubuntu + macos, shellcheck on all `*.sh`.

## 7. Versioning & Releases

- SemVer. Breaking = any change to task/state/changelog/config file contracts or hook I/O (see §3.9's format-contracts rule in CONTRIBUTING.md).
- CHANGELOG.md maintained by Thekedar itself (dogfooding).
- Release artifacts: git tag + zip. P2: Claude Code plugin marketplace packaging (F14).

## 8. Open Questions

1. Ledger rotation: daily files forever, or monthly roll-up at scale? (v2: daily, revisit if `.thekedar/changes/` grows unwieldy)
2. Windows PowerShell-native hook variants, or keep documenting Git Bash as the requirement? (v2: Git Bash; tracked for a future phase)
3. Should `scope_guard: off` (advisory) be the install default for first-time users to reduce friction, flipping to `on` only after they've seen it work once? (v2: ships `on`; revisit based on false-positive reports)
