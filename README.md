# 🏗️ Thekedar (ठेकेदार)

[![CI](https://github.com/soumyachk101/Thekedar/actions/workflows/ci.yml/badge.svg)](https://github.com/soumyachk101/Thekedar/actions/workflows/ci.yml)
[![shellcheck](https://github.com/soumyachk101/Thekedar/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/soumyachk101/Thekedar/actions/workflows/shellcheck.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Zero dependencies](https://img.shields.io/badge/dependencies-zero-brightgreen)

> **Your AI coding crew's site supervisor.** Breaks big projects into small tasks, assigns specialist agents, gates every task behind review, mechanically enforces scope, and keeps a written record of every change — so your AI never hallucinates its way through your codebase again.

*Thekedar (Hindi: ठेकेदार) — the contractor on an Indian construction site. He doesn't lay bricks himself. He splits the work, assigns the right worker to the right job, inspects everything before sign-off, and the munshi (clerk) writes it all down.*

**That's exactly what this does to your AI coding agent.**

---

## The Problem

AI coding agents are brilliant for 20 minutes, then:

1. **Context bloat → hallucination.** Give an agent a whole codebase and a vague goal, and by turn 40 it's confidently editing files that don't exist.
2. **No paper trail.** "What did the AI change yesterday?" Nobody knows. Git diff shows *what*, never *why* or *what was deliberately left alone*.
3. **One agent, every hat.** The same context window writes backend code, reviews its own security, and checks its own UI. It grades its own homework. It gives itself an A.
4. **Session dies, knowledge dies.** Crash, `/clear`, or a new day — and the agent restarts from zero.
5. **Prompting isn't enforcement.** "Don't touch that file" is a request, not a wall — and under context pressure, a request is exactly what gets forgotten first.

## The Fix

Thekedar installs a **workflow discipline** on top of Claude Code (and other agents via a generated AGENTS.md):

```
                        ┌─────────────────┐
   Big vague request →  │    THEKEDAR     │  (orchestrator skill)
                        │  (main session) │
                        └────────┬────────┘
                                 │ 1. delegate planning
                        ┌────────▼────────┐
                        │     PLANNER     │ → writes tasks/001.md, 002.md ...
                        │ (+ api-designer)│   each with scope + NOT-scope
                        └────────┬────────┘
                                 │ 2. one task at a time, routed by task type
                 ┌───────────────┼───────────────────────┐
        ┌────────▼───────┐ ┌─────────────┐      ┌────────▼────────┐
        │  BACKEND-DEV   │ │ FRONTEND-DEV│  ...  │  7 more doers   │
        │  builds task N │ │             │       │  (--full)       │
        └────────┬───────┘ └──────┬──────┘       └─────────────────┘
                 │  every Write/Edit passes through:
                 │  ┌─────────────────────────────────────────┐
                 │  │ PreToolUse: scope-guard + secret-guard   │  ← can BLOCK (exit 2)
                 │  └─────────────────────────────────────────┘
                 │  ┌─────────────────────────────────────────┐
                 │  │ PostToolUse: munshi → ledger line logged │  ← never blocks
                 │  └─────────────────────────────────────────┘
                 │ 3. review gate (parallel, read-only, fresh context each)
     ┌───────────┼──────────────┬─────────────────┬───────────────┐
┌────▼─────┐ ┌───▼───────────┐ ┌▼────────────────┐ ┌──────────────▼──┐
│ ERROR-   │ │ SECURITY-     │ │ FRONTEND-       │ │ 3 more gates     │
│ CHECKER  │ │ AUDITOR       │ │ REVIEWER        │ │ (perf/a11y/deps) │
│ (tests)  │ │ (chowkidar 🔒)│ │ (UI/UX check)   │ │ conditional      │
└────┬─────┘ └───┬───────────┘ └┬────────────────┘ └──────────────────┘
     └───────────┼──────────────┘
                 │ 4. all pass?
        ┌────────▼────────┐
        │ drift-check.sh  │ → declared vs actual scope, one honest line
        │ changelog written│ → what changed, what deliberately did NOT
        │ git checkpoint  │ → commit, next task
        └─────────────────┘
```

Every edit is logged. Every scope violation is **blocked before it happens**, not caught after. Every task is documented. Every change is reviewed by an agent that **didn't write it**. Every new session starts already briefed — [session-brief.sh](docs/HOOKS-GUIDE.md#session-briefsh) injects your project state automatically.

## The Crew — 15 agents + 5 hooks + 4 skills

| Agent | Site role | Fires when | Tools | Model |
|---|---|---|---|---|
| `planner` | नक्शा — Architect | start of any multi-step request | Read, Grep, Glob, Write | inherit |
| `api-designer` | Contract writer | task creates/changes an API surface | Read, Grep, Glob, Write | inherit |
| `backend-dev` | मिस्त्री — Mason | server/API/db/script tasks | Read, Write, Edit, Bash, Grep, Glob | sonnet |
| `frontend-dev` | रंग-मिस्त्री — Finisher | UI/component/style tasks | Read, Write, Edit, Bash, Grep, Glob | sonnet |
| `error-checker` | Inspector | every task, always. Read-only | Read, Bash, Grep, Glob | sonnet |
| `security-auditor` | चौकीदार — Guard | every task, always. Read-only | Read, Grep, Glob, Bash | sonnet |
| `frontend-reviewer` | Finisher's eye | UI files touched. Read-only | Read, Grep, Glob, Bash | sonnet |
| + 9 more (`--full`) | test-writer, db-specialist, docs-writer, devops-engineer, refactor-specialist, performance-auditor, accessibility-auditor, dependency-auditor | see [AGENTS-GUIDE.md](docs/AGENTS-GUIDE.md) | doer or gate set | sonnet/haiku |
| `munshi` (hook) | मुंशी — Clerk | every Write/Edit | bash, PostToolUse | free — never blocks |
| `scope-guard` (hook) | The fence | every Write/Edit | bash, PreToolUse | free — **blocks** confirmed misses |
| `secret-guard` (hook) | The gate check | every Write/Edit | bash, PreToolUse | free — **blocks** confirmed secrets |
| `session-brief` (hook) | Morning briefing | every session start | bash, SessionStart | free — injects state |
| `drift-check` (script) | Honest audit | end of every task | bash, orchestrator-called | free — reports, never blocks |

**Key design rules:** reviewers are **read-only** (no Write/Edit — enforced by the runtime, not a promise) and run in **separate context windows**. The agent that wrote the code never approves it. And new in v2: scope enforcement moved from *prompt* to *mechanism* — see [ADR-0006](docs/adr/0006-scope-guard-as-pretooluse.md).

## Install

```bash
# from your project root
git clone https://github.com/soumyachk101/Thekedar /tmp/thekedar && bash /tmp/thekedar/install.sh

# want the 9 extended specialists too (test-writer, db-specialist, devops-engineer, ...)?
bash /tmp/thekedar/install.sh --full
```

Or manually — it's just markdown files and bash scripts. See [INSTALL.md](INSTALL.md). Health check anytime: `bash .thekedar/scripts/doctor.sh`.

**Requirements:** Claude Code ≥ 2.x, `bash`, `git`. `jq` or `python3` recommended (hooks degrade gracefully without either). Zero npm/pip dependencies — see [ADR-0001](docs/adr/0001-markdown-as-the-interface.md).

## Quick Start

```
you: Build me a todo app with a REST API

thekedar skill activates →
  planner writes:
    .thekedar/tasks/001-project-setup.md
    .thekedar/tasks/002-db-schema.md
    .thekedar/tasks/003-todo-crud-api.md   ← api-designer writes the contract first
    ...
  backend-dev picks up 001 → implements →
    scope-guard + secret-guard check every write, munshi logs every edit
  error-checker: ✅ PASS → security-auditor: ✅ PASS →
  drift-check: none → changelog written → git commit "thekedar(task-001): ..." →
  next task.
```

Resume anytime — even in a fresh session, with **zero re-prompting**:

```
you: continue the project
      [session-brief.sh already injected PROJECT_STATE before you typed this]
claude: Tasks 001–003 done. Resuming 004-todo-list-ui...
```

**See it for real:** [examples/demo-todo-app](examples/demo-todo-app) is the actual, unedited `.thekedar/` output from Thekedar building a small todo app — 6 real task files, 6 real changelogs (including a real fix loop), a real final PROJECT_STATE.md. Not a mockup.

## What Gets Written to Disk

```
your-project/
├── .thekedar/
│   ├── PROJECT_STATE.md      ← resume-anywhere memory (auto-injected at session start)
│   ├── config.md             ← fix_loop_cap, auto_continue, scope_guard, ...
│   ├── tasks/                ← 001-setup.md, 002-schema.md ... scope, NOT-scope, acceptance
│   ├── phases/                ← phase-N.md, big projects only (>~12 tasks)
│   ├── changes/
│   │   ├── ledger-2026-07-09.md   ← munshi's per-edit log (automatic, free)
│   │   └── task-001.md            ← rich per-task changelog (what/NOT/why/verdicts/drift)
│   └── scripts/               ← doctor, export-agents-md, new-agent, report, stats
└── .claude/
    ├── agents/
    │   ├── core/              ← 6 agents, always installed
    │   ├── extended/          ← 9 more, --full
    │   └── custom/            ← yours, via new-agent.sh
    ├── skills/                ← thekedar, thekedar-status, thekedar-report, thekedar-plan
    ├── hooks/                 ← munshi, scope-guard, secret-guard, session-brief, drift-check
    └── settings.json          ← hook wiring (merged, never silently overwritten)
```

## Why Small, Guarded Tasks Kill Hallucination

An agent hallucinates when its context is stuffed with irrelevant code and its goal is vague. Thekedar attacks both:

- **Scoped tasks** — each task file states what to build AND what NOT to touch. The doer agent loads one task, not the universe.
- **Mechanically enforced scope** — `scope-guard.sh` blocks a write outside the declared files *before it lands*, not after a human notices in review.
- **Fresh contexts** — subagents spawn clean. No 200-message history poisoning the work.
- **External memory** — state lives in markdown on disk, not in a fragile context window, and gets re-injected automatically at every new session.
- **Independent review** — a hallucinated function fails `error-checker` because the reviewer actually runs the tests.

## Honest Notes (padh lo, zaroori hai)

- **Token cost is real.** Multi-agent means 2–4× tokens vs a raw single session (methodology for measuring this precisely: [BENCHMARKS.md](docs/BENCHMARKS.md) — no numbers published yet, only honest ones will be). That's why doers/reviewers default to Sonnet (Haiku where the task is lighter) and only planning gets the big model. For a throwaway script, don't use Thekedar. For anything you'll maintain — worth it.
- **Munshi is deterministic, not smart. The two guards are deterministic and strict.** The ledger hook logs *facts* for free. scope-guard and secret-guard *block* — but only on a confirmed hit; every doubt fails open (see [ADR-0002](docs/adr/0002-hooks-never-block-except-guards.md)). The *reasoning* changelog is still written per-task by the orchestrator.
- **Reviewers can be wrong.** They massively cut slip-through rate; they don't replace your eyes on a final PR.
- **Two sessions, one repo, at once — don't.** v2 doesn't solve concurrent-session races yet. See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Docs

- [PRD — what & why](docs/PRD.md) · [TRD — how, exactly](docs/TRD.md) · [Architecture deep-dive](docs/ARCHITECTURE.md)
- [Full workflow walkthrough](docs/WORKFLOW.md) · [Agents guide](docs/AGENTS-GUIDE.md) · [Hooks guide](docs/HOOKS-GUIDE.md) · [Commands](docs/COMMANDS.md)
- [Customization](docs/CUSTOMIZATION.md) · [Troubleshooting](docs/TROUBLESHOOTING.md) · [FAQ](docs/FAQ.md) · [Comparison](docs/COMPARISON.md) · [Benchmarks](docs/BENCHMARKS.md)
- [Architecture Decision Records](docs/adr/) · [Install guide (all tools)](INSTALL.md) · [Roadmap](ROADMAP.md) · [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md)

## Inspired By

- [caveman](https://github.com/JuliusBrussee/caveman) — proof that a personality + one sharp idea + zero deps = a great agent tool
- Spec-driven development (OpenSpec, spec-kit) — small scoped specs beat big vague prompts
- Every thekedar on every Indian construction site who never let bad work pass 🫡

## License

MIT — see [LICENSE](LICENSE).

---

*Kaam pakka, hisaab saaf.* (Solid work, clean records.)
