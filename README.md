# 🏗️ Thekedar (ठेकेदार)

> **Your AI coding crew's site supervisor.** Breaks big projects into small tasks, assigns specialist agents, gates every task behind review, and keeps a written record of every change — so your AI never hallucinates its way through your codebase again.

*Thekedar (Hindi: ठेकेदार) — the contractor on an Indian construction site. He doesn't lay bricks himself. He splits the work, assigns the right worker to the right job, inspects everything before sign-off, and the munshi (clerk) writes it all down.*

**That's exactly what this does to your AI coding agent.**

---

## The Problem

AI coding agents are brilliant for 20 minutes, then:

1. **Context bloat → hallucination.** Give an agent a whole codebase and a vague goal, and by turn 40 it's confidently editing files that don't exist.
2. **No paper trail.** "What did the AI change yesterday?" Nobody knows. Git diff shows *what*, never *why* or *what was deliberately left alone*.
3. **One agent, every hat.** The same context window writes backend code, reviews its own security, and checks its own UI. It grades its own homework. It gives itself an A.
4. **Session dies, knowledge dies.** Crash, `/clear`, or a new day — and the agent restarts from zero.

## The Fix

Thekedar installs a **workflow discipline** on top of Claude Code (and other agents via the AGENTS.md standard):

```
                        ┌─────────────────┐
   Big vague request →  │    THEKEDAR     │  (orchestrator skill)
                        │  (main session) │
                        └────────┬────────┘
                                 │ 1. delegate planning
                        ┌────────▼────────┐
                        │     PLANNER     │ → writes tasks/001.md, 002.md ...
                        │  (small tasks)  │   each with scope + NOT-scope
                        └────────┬────────┘
                                 │ 2. one task at a time
                 ┌───────────────┼───────────────┐
        ┌────────▼───────┐              ┌────────▼────────┐
        │  BACKEND-DEV   │              │  (other doers)  │
        │  builds task N │              │                 │
        └────────┬───────┘              └─────────────────┘
                 │ 3. review gate (parallel)
     ┌───────────┼──────────────┬─────────────────┐
┌────▼─────┐ ┌───▼───────────┐ ┌▼─────────────────┐
│ ERROR-   │ │ SECURITY-     │ │ FRONTEND-        │
│ CHECKER  │ │ AUDITOR       │ │ REVIEWER         │
│ (tests)  │ │ (chowkidar 🔒)│ │ (UI/UX check)    │
└────┬─────┘ └───┬───────────┘ └┬─────────────────┘
     └───────────┼──────────────┘
                 │ 4. all pass?
        ┌────────▼────────┐
        │  MUNSHI (hook)  │ → changelog .md written automatically
        │  git checkpoint │ → commit, next task
        └─────────────────┘
```

Every edit is logged. Every task is documented. Every change is reviewed by an agent that **didn't write it**.

## The Crew

| Agent | Site role | Job | Tools | Model |
|---|---|---|---|---|
| `thekedar` (skill) | ठेकेदार — Supervisor | Orchestrates the whole workflow, one task at a time | Task + all | inherit |
| `planner` | नक्शा — Architect | Splits project into small, scoped task files | Read, Grep, Glob, Write | opus/inherit |
| `backend-dev` | मिस्त्री — Mason | Implements exactly ONE task, nothing more | Read, Write, Edit, Bash, Grep, Glob | sonnet |
| `error-checker` | Inspector | Runs tests & lint, reports by severity. Read-only | Read, Bash, Grep, Glob | sonnet |
| `security-auditor` | चौकीदार — Guard | OWASP checks, secret scan, injection hunt. Read-only | Read, Grep, Glob, Bash | sonnet |
| `frontend-reviewer` | Finisher | Reviews UI code: accessibility, responsiveness, consistency. Read-only | Read, Grep, Glob, Bash | sonnet |
| `munshi` (hook) | मुंशी — Clerk | Deterministic ledger: logs every file edit as it happens | bash script | none (free!) |

**Key design rule:** reviewers are **read-only** and run in **separate context windows**. The agent that wrote the code never approves it.

## Install

```bash
# from your project root
git clone https://github.com/soumyachk101/Thekedar /tmp/thekedar && bash /tmp/thekedar/install.sh
```

Or manually — it's just markdown files and one bash script. See [INSTALL.md](INSTALL.md).

**Requirements:** Claude Code ≥ 2.x, `bash`, `git`. `jq` or `python3` recommended for the munshi hook. Zero npm dependencies.

## Quick Start

```
you: Build me a todo app with auth and a REST API

thekedar skill activates →
  planner writes:
    .thekedar/tasks/001-project-setup.md
    .thekedar/tasks/002-db-schema.md
    .thekedar/tasks/003-auth-endpoints.md
    ...
  backend-dev picks up 001 → implements → 
  error-checker: ✅ PASS → security-auditor: ✅ PASS →
  munshi logs → git commit "task-001: project setup" →
  next task.
```

Resume anytime — even in a fresh session:

```
you: continue the project
claude: [reads .thekedar/PROJECT_STATE.md] 
        Tasks 001–003 done. Resuming 004-todo-crud...
```

## What Gets Written to Disk

```
your-project/
├── .thekedar/
│   ├── PROJECT_STATE.md      ← resume-anywhere memory
│   ├── tasks/
│   │   ├── 001-setup.md      ← scope, NOT-scope, acceptance criteria
│   │   └── 002-auth.md
│   └── changes/
│       ├── ledger-2026-07-09.md   ← munshi's per-edit log (automatic)
│       └── task-001.md            ← rich per-task changelog
└── .claude/
    ├── agents/               ← the crew (5 subagents)
    ├── skills/thekedar/      ← the orchestrator skill
    ├── hooks/munshi.sh
    └── settings.json         ← hook wiring
```

## Why Small Tasks Kill Hallucination

An agent hallucinates when its context is stuffed with irrelevant code and its goal is vague. Thekedar attacks both:

- **Scoped tasks** — each task file states what to build AND what NOT to touch. The doer agent loads one task, not the universe.
- **Fresh contexts** — subagents spawn clean. No 200-message history poisoning the work.
- **External memory** — state lives in markdown on disk, not in a fragile context window.
- **Independent review** — a hallucinated function fails `error-checker` because the reviewer actually runs the tests.

## Honest Notes (padh lo, zaroori hai)

- **Token cost is real.** Multi-agent means 2–4× tokens vs a raw single session. That's why doers/reviewers default to Sonnet and only planning gets the big model. For a throwaway script, don't use Thekedar. For anything you'll maintain — worth it.
- **Munshi is deterministic, not smart.** The hook logs *facts* (file, tool, time) for free. The *reasoning* changelog is written per-task by the orchestrator. Best of both: zero-cost ledger + meaningful docs.
- **Reviewers can be wrong.** They massively cut slip-through rate; they don't replace your eyes on a final PR.

## Docs

- [Install guide (all tools)](INSTALL.md)
- [Roadmap](ROADMAP.md)
- [Contributing](CONTRIBUTING.md)

## Inspired By

- [caveman](https://github.com/JuliusBrussee/caveman) — proof that a personality + one sharp idea + zero deps = a great agent tool
- Spec-driven development (OpenSpec, spec-kit) — small scoped specs beat big vague prompts
- Every thekedar on every Indian construction site who never let bad work pass 🫡

## License

MIT — see [LICENSE](LICENSE).

---

*Kaam pakka, hisaab saaf.* (Solid work, clean records.)
