# PRD — Thekedar

**Product Requirements Document**
Version 1.0 · July 2026 · Status: Draft for v1 build

---

## 1. Vision

Make AI coding agents **trustworthy on real projects** by imposing the discipline of a construction site: work is planned before it's built, split into small verifiable pieces, built by specialists, inspected by independent reviewers, and recorded in writing — automatically.

One-line pitch: *"The site supervisor for your AI coding crew."*

## 2. Problem Statement

Developers using Claude Code, Cursor, Codex, and similar agents on non-trivial projects hit four recurring failures:

**P1 — Hallucination under context pressure.** When the whole codebase plus a long conversation fills the context window, agents invent APIs, edit non-existent files, and drift from the goal. Root cause: too much irrelevant context + vaguely scoped goals.

**P2 — No audit trail.** Git records *what* changed, never *why*, and never *what was deliberately not changed*. Teams cannot review, trust, or debug days of agent-driven work.

**P3 — Self-review is no review.** A single agent writes code, then "checks" it in the same context that produced the bug. Error, security, and UI quality all suffer because the checker shares the writer's blind spots.

**P4 — Session amnesia.** A crash, a `/clear`, or simply tomorrow morning wipes all working memory. Re-onboarding the agent costs time and re-introduces drift.

## 3. Goals

| # | Goal | Measured by |
|---|---|---|
| G1 | Reduce hallucinated/broken output on multi-hour projects | % of tasks passing error-checker on first attempt; user reports |
| G2 | Produce a complete, human-readable change record with zero manual effort | Every completed task has a changelog entry; every file edit appears in the ledger |
| G3 | Independent quality gates on every task | 100% of tasks reviewed by ≥1 read-only agent that did not author the code |
| G4 | Resume any project in a fresh session in < 1 minute | Fresh session reads PROJECT_STATE.md and continues correct next task |
| G5 | Install in under 60 seconds, zero runtime dependencies | Time from clone to first orchestrated task |

## 4. Non-Goals (v1)

- Not a hosted service, SaaS, or web dashboard. Files on disk only.
- Not a replacement for human PR review — it reduces load, doesn't eliminate it.
- Not a token-compression tool (that's caveman's job; the two compose nicely).
- No GUI. No database. No telemetry.
- Agent Teams / multi-session orchestration (experimental in Claude Code) — deferred to v2.

## 5. Target Users

1. **Solo builder / indie hacker** — ships side projects with Claude Code; wants fewer 2 a.m. "why is this file gone" moments.
2. **Small dev team (2–10)** — commits `.claude/` to the repo so every member's agent follows the same discipline; changelog doubles as async standup notes.
3. **AI-curious engineering lead** — needs an audit trail before allowing agents near production code.

## 6. User Stories

- *As a solo dev*, I say "build feature X" and the system plans it into small tasks before writing any code, so I can correct the plan cheaply.
- *As a dev*, every task the agent completes is automatically documented (what changed, what didn't, why), so I can review a day's work in 5 minutes.
- *As a dev*, an independent agent runs my tests and a security scan after each task, so broken or vulnerable code never silently accumulates.
- *As a team lead*, I open `.thekedar/changes/` and see exactly which agent touched which file and when.
- *As a returning user*, I open a fresh session, type "continue", and the agent resumes the correct task without re-explanation.
- *As a Cursor/Codex user*, I get the same workflow via the AGENTS.md standard without Claude-Code-specific features.

## 7. Features & Priorities

### P0 — must ship in v1

| ID | Feature | Description |
|---|---|---|
| F1 | **Orchestrator skill** | `thekedar` skill enforcing the loop: plan → build one task → review gates → log → git checkpoint → next |
| F2 | **Planner agent** | Decomposes a request into task files using the task template; each task has scope, NOT-scope, acceptance criteria |
| F3 | **Doer agent (backend-dev)** | Implements exactly one task; forbidden from touching files outside declared scope |
| F4 | **Reviewer agents ×3** | `error-checker` (tests/lint), `security-auditor` (OWASP/secrets), `frontend-reviewer` (UI). All read-only, separate contexts |
| F5 | **Munshi hook** | PostToolUse hook: deterministic per-edit ledger written to `.thekedar/changes/ledger-DATE.md`. Never blocks, zero tokens |
| F6 | **Per-task changelog** | Orchestrator writes `changes/task-NNN.md` from template on task completion: changed / NOT changed / why / verification results |
| F7 | **PROJECT_STATE.md** | Single source of truth: phase, active task, done list, decisions, known issues. Updated after every task |
| F8 | **Git checkpoints** | Auto-commit after each task passes review; rollback = `git revert` one commit |
| F9 | **Installer** | `install.sh`: copies agents/skill/hook/templates into the project, merges hook config into `.claude/settings.json` safely |

### P1 — fast follow

| ID | Feature | Description |
|---|---|---|
| F10 | **AGENTS.md export** | Generate an AGENTS.md encoding the workflow for Cursor, Codex, Copilot, etc. |
| F11 | **Context budget guard** | Rule in skill: when context feels heavy, dump state to disk and recommend `/compact` or a fresh session |
| F12 | **Drift detector** | Post-task check: diff actual changed files vs task's declared file list; flag out-of-scope edits |
| F13 | **`/thekedar-status` command** | One-shot summary from PROJECT_STATE + ledger |

### P2 — later

| ID | Feature | Description |
|---|---|---|
| F14 | Plugin marketplace packaging (`claude plugin install thekedar@thekedar`) |
| F15 | Agent Teams mode (parallel independent tasks across sessions) |
| F16 | Configurable crew (user adds e.g. `db-migrations` agent via template) |
| F17 | HTML report generator from ledger + changelogs |

## 8. Success Metrics

- ⭐ 500 GitHub stars in 90 days (proxy for resonance)
- ≥ 80% of orchestrated tasks pass error-checker on first attempt (self-reported benchmark repo)
- Fresh-session resume works with zero re-prompting in the demo project
- Install-to-first-task < 60 s on macOS/Linux/WSL
- ≤ 1 open "hook broke my session" issue per release (munshi must be bulletproof: always exit 0)

## 9. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Token cost of multi-agent scares users | Adoption | Honest README section; Sonnet defaults for doers/reviewers; reviewers run only per-task, not per-edit |
| Hook bugs block user's tool calls | Trust-killer | Munshi always exits 0; wraps everything in `|| true`; logs failures silently to its own file |
| Per-edit logging too noisy | Annoyance | Ledger = one line per edit; rich narrative only per task |
| Claude Code API/format changes | Breakage | Pin docs links; CI check against latest Claude Code; formats verified against official docs at build time |
| Over-orchestration on tiny asks | UX | Skill explicitly exempts trivial requests (< 1 task): "do it directly, skip ceremony" |
| Name collision / discoverability | Growth | "thekedar" is unique on GitHub; topics: claude-code, agents, multi-agent, changelog |

## 10. Competitive Landscape

- **caveman** — token compression; orthogonal, composes with Thekedar.
- **OpenSpec / spec-kit** — spec-driven planning; Thekedar adds execution discipline, review gates, and automatic records on top of the same philosophy.
- **claude-flow / agent orchestration frameworks** — heavyweight, npm-based, often abandoned. Thekedar's bet: markdown + bash + git = boring, durable, auditable.

Differentiator: **nobody combines** task chunking + independent multi-agent review + automatic written records in one zero-dependency install.
