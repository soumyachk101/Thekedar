# THEKEDAR — MASTER BUILD BLUEPRINT (v2 "Massive")

> **How to use this file:** Put it in an empty folder. Open Claude Code there. Paste the
> KICKOFF PROMPT from §5. Claude Code builds the repo phase by phase, checkpointing with
> git after every phase. You review each phase before the next begins.
>
> This blueprint IS the spec. Claude Code must not invent files or features beyond it.
> Reference implementations for 21 of these files exist in the v1 zip (thekedar.zip) —
> reuse and improve them rather than rewriting from scratch.

---

## §1 — THE COMPLETE TREE (~90 files)

```
thekedar/
│
│  # ── Root docs & meta ─────────────────────────────────
├── README.md                  ← the face: problem, crew table, install, demo, honest notes
├── INSTALL.md                 ← all install paths + verify + troubleshooting
├── CONTRIBUTING.md            ← zero-dep law, hook tests, prompt-PR evidence rule
├── CODE_OF_CONDUCT.md         ← Contributor Covenant 2.1, contact placeholder
├── SECURITY.md                ← how to report vulns; what munshi/hooks can and can't touch
├── CHANGELOG.md               ← Keep-a-Changelog format; v2.0.0 entry written by Thekedar itself
├── ROADMAP.md                 ← shipped / next / non-goals
├── LICENSE                    ← MIT
├── VERSION                    ← plain text: 2.0.0
├── .gitignore
│
│  # ── Install & lifecycle scripts ──────────────────────
├── install.sh                 ← idempotent; copies everything below; safe settings.json merge
├── uninstall.sh               ← removes agents/skills/hooks + settings entries; keeps .thekedar/
├── update.sh                  ← git pull source + re-run install.sh with backups
│
├── scripts/
│   ├── doctor.sh              ← health check: files present, hook executable+exit0, settings wired, git ok
│   ├── export-agents-md.sh    ← flattens workflow into AGENTS.md for Cursor/Codex/Copilot
│   ├── new-agent.sh           ← scaffolds a custom agent from templates/agent-template.md
│   ├── report.sh              ← ledger + changelogs + git log → REPORT.md (project summary)
│   └── stats.sh               ← counts: tasks done, edits logged, fix-loops used, files touched
│
│  # ── GitHub infrastructure ────────────────────────────
├── .github/
│   ├── FUNDING.yml
│   ├── PULL_REQUEST_TEMPLATE.md      ← includes "attach your changes/task-*.md" (dogfood rule)
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── agent_improvement.md      ← requires before/after transcript evidence
│   └── workflows/
│       ├── ci.yml                    ← runs tests/run-all.sh on push/PR (ubuntu + macos)
│       └── shellcheck.yml            ← shellcheck on all *.sh
│
│  # ── Documentation ────────────────────────────────────
├── docs/
│   ├── PRD.md                 ← expand v1: add F18-F30 for new agents/hooks/commands
│   ├── TRD.md                 ← expand v1: scope-guard protocol, SessionStart injection, config spec
│   ├── ARCHITECTURE.md        ← expand v1: 5-hook diagram, guard-rail layer
│   ├── WORKFLOW.md            ← full annotated walkthrough of one real task, turn by turn
│   ├── AGENTS-GUIDE.md        ← all 15 agents: when they fire, tools, model, sample verdict
│   ├── HOOKS-GUIDE.md         ← all 5 hooks: event, matcher, I/O, exit codes, how to disable
│   ├── COMMANDS.md            ← the 4 slash commands with example outputs
│   ├── CUSTOMIZATION.md       ← config.md options, adding agents, swapping models, disabling reviewers
│   ├── TROUBLESHOOTING.md     ← every known failure + fix (feeds from real issues over time)
│   ├── FAQ.md                 ← token cost, when NOT to use, vs caveman, single-agent mode
│   ├── COMPARISON.md          ← vs raw Claude Code, OpenSpec, claude-flow; honest table
│   ├── BENCHMARKS.md          ← methodology + honest numbers (caveman-style credibility)
│   └── adr/                   ← Architecture Decision Records (the "why" archive)
│       ├── 0001-markdown-as-the-interface.md
│       ├── 0002-hooks-never-block-except-guards.md
│       ├── 0003-per-task-changelog-not-per-edit.md
│       ├── 0004-readonly-reviewers-via-tool-allowlist.md
│       ├── 0005-model-routing-sonnet-workers.md
│       ├── 0006-scope-guard-as-pretooluse.md
│       └── 0007-dotthekedar-vs-dotclaude-split.md
│
│  # ── The Crew: 15 subagents ───────────────────────────
├── .claude/
│   ├── settings.json          ← wires all 5 hooks (see §2.3)
│   ├── agents/
│   │   ├── core/                       # installed by default
│   │   │   ├── planner.md              # v1, expanded: phases, open-questions protocol
│   │   │   ├── backend-dev.md          # v1, expanded: scope-addition protocol
│   │   │   ├── frontend-dev.md         # NEW doer: UI implementation specialist
│   │   │   ├── error-checker.md        # v1
│   │   │   ├── security-auditor.md     # v1
│   │   │   └── frontend-reviewer.md    # v1
│   │   └── extended/                   # installed with --full flag
│   │       ├── test-writer.md          # writes missing tests as its own task type
│   │       ├── db-specialist.md        # schema, migrations, query review
│   │       ├── api-designer.md         # designs API contracts BEFORE backend-dev builds
│   │       ├── docs-writer.md          # user-facing docs from changelogs
│   │       ├── performance-auditor.md  # read-only: N+1s, hot loops, bundle size
│   │       ├── accessibility-auditor.md# read-only: WCAG-focused deep pass
│   │       ├── dependency-auditor.md   # read-only: new deps, licenses, CVEs, typosquats
│   │       ├── devops-engineer.md      # Dockerfiles, CI configs, env handling
│   │       └── refactor-specialist.md  # structured refactors with behavior-lock tests first
│   └── (hooks installed here by install.sh; source lives in /hooks)
│
│  # ── Skills: orchestrator + 3 slash commands ──────────
├── skills/
│   ├── thekedar/SKILL.md              ← v1 state machine + config loading + guard awareness
│   ├── thekedar-status/SKILL.md       ← /thekedar-status → 6-line status from STATE+ledger+git
│   ├── thekedar-report/SKILL.md       ← /thekedar-report → runs scripts/report.sh, summarizes
│   └── thekedar-plan/SKILL.md         ← /thekedar-plan → planner only, no execution (review plans cheaply)
│
│  # ── Hooks: the deterministic layer ───────────────────
├── hooks/
│   ├── munshi.sh              ← v1: PostToolUse ledger; ALWAYS exit 0
│   ├── scope-guard.sh         ← NEW PreToolUse(Write|Edit): blocks edits outside ACTIVE task's
│   │                             Expected files (+Scope additions). exit 2 + stderr instructs
│   │                             the model to add a Scope addition first. THE killer feature.
│   ├── secret-guard.sh        ← NEW PreToolUse(Write|Edit): regex-scans content being written
│   │                             for keys/tokens/passwords; exit 2 on hit
│   ├── session-brief.sh       ← NEW SessionStart: prints PROJECT_STATE.md → auto-injected
│   │                             context = zero-prompt resume
│   └── drift-check.sh         ← called by orchestrator at task end: git diff names vs
│                                 Expected files → drift report line for the changelog
│
│  # ── Templates ────────────────────────────────────────
├── templates/
│   ├── task.md                ← v1 + Risk field + Estimated size field
│   ├── PROJECT_STATE.md       ← v1 + Phases section
│   ├── changelog-entry.md     ← v1 + Drift report line
│   ├── agent-template.md      ← for scripts/new-agent.sh
│   ├── decision-record.md     ← ADR template for user projects
│   ├── phase.md               ← groups tasks for big projects
│   └── config.md              ← the default .thekedar/config.md (see §2.4)
│
│  # ── Tests (CI runs these) ────────────────────────────
├── tests/
│   ├── run-all.sh             ← runs every test-*.sh; non-zero on any failure
│   ├── test-munshi.sh         ← valid / malformed / empty / huge input / readonly-fs → exit 0 always
│   ├── test-scope-guard.sh    ← in-scope allow(0), out-of-scope block(2), no-active-task allow(0)
│   ├── test-secret-guard.sh   ← clean allow, AWS-key/JWT/private-key block, false-positive checks
│   ├── test-session-brief.sh  ← with/without STATE file
│   ├── test-installer.sh      ← fresh install, idempotent rerun, existing-settings merge, --full
│   ├── test-export-agents.sh  ← AGENTS.md generated, contains workflow sections
│   └── fixtures/
│       ├── valid-edit.json
│       ├── malformed.json
│       ├── secret-payload.json
│       └── out-of-scope-edit.json
│
│  # ── Examples (proof for visitors) ────────────────────
├── examples/
│   └── demo-todo-app/
│       ├── README.md                  ← "this is real output, generated by Thekedar building a todo app"
│       └── .thekedar/
│           ├── PROJECT_STATE.md       ← final state after 6 tasks
│           ├── tasks/001-setup.md … 006-polish.md
│           └── changes/
│               ├── ledger-sample.md
│               └── task-001.md … task-006.md
│
└── assets/
    └── banner.txt             ← ASCII-art logo used in README + doctor.sh output
```

---

## §2 — CRITICAL SPECS (build exactly this)

### 2.1 The 15 agents — role matrix

| Agent | Type | Tools | Model | Fires when |
|---|---|---|---|---|
| planner | brain | Read, Grep, Glob, Write | inherit | start of any multi-step request; re-plans |
| api-designer | brain | Read, Grep, Glob, Write | inherit | task involves new/changed API surface — runs BEFORE backend-dev, writes contract into the task file |
| backend-dev | doer | Read, Write, Edit, Bash, Grep, Glob | sonnet | server/API/db/script tasks |
| frontend-dev | doer | Read, Write, Edit, Bash, Grep, Glob | sonnet | UI/component/style tasks |
| test-writer | doer | Read, Write, Edit, Bash, Grep, Glob | sonnet | test-gap tasks; behavior-lock tests before refactors |
| db-specialist | doer | Read, Write, Edit, Bash, Grep, Glob | sonnet | schema/migration tasks; reviews query patterns |
| devops-engineer | doer | Read, Write, Edit, Bash, Grep, Glob | sonnet | Docker/CI/env tasks |
| refactor-specialist | doer | Read, Write, Edit, Bash, Grep, Glob | sonnet | refactor tasks; MUST have test-writer lock behavior first |
| docs-writer | doer | Read, Write, Grep, Glob | haiku | docs tasks; sources = changelogs + code |
| error-checker | gate | Read, Bash, Grep, Glob | sonnet | EVERY task, always |
| security-auditor | gate | Read, Grep, Glob, Bash | sonnet | EVERY task, always |
| frontend-reviewer | gate | Read, Grep, Glob, Bash | sonnet | UI files touched |
| performance-auditor | gate | Read, Grep, Glob, Bash | sonnet | config-enabled OR task tagged `perf` |
| accessibility-auditor | gate | Read, Grep, Glob, Bash | sonnet | config-enabled OR task tagged `a11y` |
| dependency-auditor | gate | Read, Grep, Glob, Bash | haiku | manifest files changed |

Iron rules: gates NEVER have Write/Edit. Every gate returns the standard VERDICT format
(PASS/FAIL + severity findings, as in v1 error-checker). Doers never commit. Every agent's
description starts with "MUST BE USED..." trigger phrasing for reliable auto-delegation.

### 2.2 scope-guard.sh — exact protocol (the crown jewel)

- Event: **PreToolUse**, matcher `Write|Edit|MultiEdit`.
- Read stdin JSON → `tool_input.file_path`.
- Find the ACTIVE task: grep `.thekedar/tasks/*.md` for `**Status:** ACTIVE`.
- **No ACTIVE task → exit 0** (guard only guards during orchestrated work; trivial mode unaffected).
- Build allowlist: paths under "## Expected files" + "## Scope addition" sections of that task,
  plus always-allowed: `.thekedar/**` (state/logs/tasks must stay writable).
- Path in allowlist → exit 0. Not in list → **exit 2**, stderr:
  `SCOPE-GUARD: <path> is outside task NNN's declared files. Either add a "## Scope addition" entry (file + one-line reason) to the task file first, or leave this file alone.`
- Same bulletproofing as munshi: any internal failure → exit 0 (fail-open; guard must never
  brick a session). jq → python3 → grep fallback chain. < 50 ms.

### 2.3 settings.json — full wiring

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command",
        "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/session-brief.sh\"" } ] }
    ],
    "PreToolUse": [
      { "matcher": "Write|Edit|MultiEdit", "hooks": [
        { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/scope-guard.sh\"" },
        { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/secret-guard.sh\"" }
      ] }
    ],
    "PostToolUse": [
      { "matcher": "Write|Edit|MultiEdit", "hooks": [
        { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/munshi.sh\"" }
      ] }
    ]
  }
}
```

### 2.4 .thekedar/config.md (parsed by orchestrator, simple `key: value` lines)

```
fix_loop_cap: 3
auto_continue: true          # false = pause for user between tasks
default_doer_model: sonnet
enable_performance_auditor: false
enable_accessibility_auditor: false
scope_guard: on              # off = advisory only (log, don't block)
commit_prefix: "thekedar"
```

### 2.5 Non-negotiables (carry from v1, verify in every phase)

1. Zero runtime dependencies. jq/python3 optional-if-present only.
2. munshi + session-brief + drift-check: ALWAYS exit 0. Guards: exit 2 only on a
   confirmed hit, exit 0 on any internal doubt/failure.
3. All formats (task/STATE/changelog) are contracts → changing them = major version.
4. Every shell script passes shellcheck. Every hook has fixture tests. CI green before any release.
5. Honest docs: BENCHMARKS.md publishes methodology + real numbers, including where
   Thekedar loses (tiny tasks, token overhead).

---

## §3 — PHASED BUILD PLAN (feed one phase at a time)

> Each phase = one Thekedar-style scope. Finish → test → `git commit -m "phase-N: <name>"` → show
> me a 5-line summary → WAIT for my go-ahead. Never start phase N+1 unsolicited.

**Phase 0 — Foundation.** git init; LICENSE, VERSION, .gitignore, banner.txt, README skeleton
(title, tagline, "under construction 🏗️", tree). ✅ repo commits clean.

**Phase 1 — Deterministic layer.** hooks/munshi.sh (port from v1), scope-guard.sh, secret-guard.sh,
session-brief.sh, drift-check.sh + tests/fixtures + tests/test-*.sh + tests/run-all.sh.
✅ `bash tests/run-all.sh` exits 0; shellcheck clean.

**Phase 2 — Templates & config.** All 7 templates + config.md defaults.
✅ every template has all required sections from §2 specs.

**Phase 3 — Core crew.** 6 core agents (port 5 from v1, write frontend-dev new).
✅ valid frontmatter (name/description/tools/model) on all; gates have no Write/Edit.

**Phase 4 — Extended crew.** 9 extended agents per the role matrix.
✅ same frontmatter validation; each description starts with "MUST BE USED".

**Phase 5 — Skills.** thekedar SKILL.md (v1 + config loading + guard awareness + drift-check call
in §4-LOG) + the 3 command skills. ✅ orchestrator references config keys and drift-check correctly.

**Phase 6 — Lifecycle scripts.** install.sh (v1 + hooks×5 + --full flag + core/extended split),
uninstall.sh, update.sh, scripts/{doctor,new-agent,export-agents-md,report,stats}.sh + installer/export tests.
✅ fresh install + rerun + uninstall all verified in a scratch repo; doctor.sh all-green after install.

**Phase 7 — Docs.** Expand PRD/TRD/ARCHITECTURE from v1; write WORKFLOW, AGENTS-GUIDE, HOOKS-GUIDE,
COMMANDS, CUSTOMIZATION, TROUBLESHOOTING, FAQ, COMPARISON, BENCHMARKS(methodology now, numbers later);
7 ADRs. ✅ no doc contradicts a spec in this blueprint; all cross-links resolve.

**Phase 8 — GitHub infra.** Issue/PR templates, FUNDING.yml, ci.yml (run-all.sh on ubuntu+macos),
shellcheck.yml, CODE_OF_CONDUCT, SECURITY, CONTRIBUTING (v1 + new hook rules), CHANGELOG v2.0.0 entry.
✅ `act`-style dry read of workflows: paths and commands exist.

**Phase 9 — Examples + README final.** Generate examples/demo-todo-app/.thekedar/* as realistic
sample output (6 tasks, ledger, changelogs); write full README (crew table of 15, 5-hook diagram,
install, demo, honest notes, docs links); ROADMAP final. ✅ README renders clean; every link works.

**Phase 10 — Release audit.** Run doctor + all tests; self-review pass with error-checker +
security-auditor style scrutiny on the shell scripts; tag v2.0.0.
✅ CI green, shellcheck clean, honest-notes section survives.

---

## §4 — BUILD GUARDRAILS (for the Claude Code session)

- This file is the single source of truth. If something is ambiguous, ASK; never invent.
- One phase at a time; commit per phase; wait for approval between phases.
- Reuse v1 files where marked "port from v1" — improve, don't rewrite blind.
- Every bash file: `#!/usr/bin/env bash`, quoted paths, shellcheck-clean, defensive.
- Never fabricate benchmark numbers, star counts, or testimonials anywhere in docs.
- If context is getting heavy mid-phase, finish the current file, commit WIP, and say so.

## §5 — KICKOFF PROMPT (paste this into Claude Code)

```
Read BLUEPRINT.md fully. You are building the Thekedar project exactly per that
blueprint. Rules: follow §4 guardrails strictly; build ONE phase at a time starting
with Phase 0; after each phase run its acceptance checks, git commit as
"phase-N: <name>", give me a 5-line summary, and STOP for my approval.
The v1 reference implementation is in ./reference/ (if present) — port marked files
from there. Begin Phase 0 now.
```

*(Optional but smart: extract thekedar.zip into ./reference/ first so Claude Code can port
the tested v1 files instead of rewriting them.)*
