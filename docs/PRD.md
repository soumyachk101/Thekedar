# PRD — Thekedar

**Product Requirements Document**
Version 2.0 · July 2026 · Status: v2.0.0 shipped (Phases 0–6 of BLUEPRINT.md)

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

v2 adds a fifth, discovered while dogfooding v1:

**P5 — Prompting isn't enforcement.** v1's "NOT in scope" section was a request, not a fence — a doer under pressure could still touch an adjacent file, and nothing caught it until a human noticed in review. Advisory text doesn't hold under context pressure any better than the model's own judgment does.

## 3. Goals

| # | Goal | Measured by |
|---|---|---|
| G1 | Reduce hallucinated/broken output on multi-hour projects | % of tasks passing error-checker on first attempt; user reports |
| G2 | Produce a complete, human-readable change record with zero manual effort | Every completed task has a changelog entry; every file edit appears in the ledger |
| G3 | Independent quality gates on every task | 100% of tasks reviewed by ≥1 read-only agent that did not author the code |
| G4 | Resume any project in a fresh session in < 1 minute | session-brief.sh injects PROJECT_STATE automatically; zero re-prompting needed |
| G5 | Install in under 60 seconds, zero runtime dependencies | Time from clone to first orchestrated task |
| G6 (v2) | Make scope violations structurally impossible, not just discouraged | scope-guard.sh blocks out-of-scope writes at the tool-call layer, not the prompt layer |

## 4. Non-Goals (v2)

- Not a hosted service, SaaS, or web dashboard. Files on disk only.
- Not a replacement for human PR review — it reduces load, doesn't eliminate it.
- Not a token-compression tool (that's caveman's job; the two compose nicely).
- No GUI. No database. No telemetry.
- Agent Teams / multi-session parallel orchestration — deferred (experimental in Claude Code; tracked as F15).
- Plugin marketplace packaging — deferred (F14; needs the marketplace to stabilize).
- The 800–1200-file "Mega" specialist-catalog expansion (MEGA_EXPANSION.md, Phases 11–20) — a separate, later scale-up. v2.0.0 ships the workflow engine only.

## 5. Target Users

1. **Solo builder / indie hacker** — ships side projects with Claude Code; wants fewer 2 a.m. "why is this file gone" moments.
2. **Small dev team (2–10)** — commits `.claude/` to the repo so every member's agent follows the same discipline; changelog doubles as async standup notes.
3. **AI-curious engineering lead** — needs an audit trail before allowing agents near production code.

## 6. User Stories

- *As a solo dev*, I say "build feature X" and the system plans it into small tasks before writing any code, so I can correct the plan cheaply.
- *As a dev*, every task the agent completes is automatically documented (what changed, what didn't, why), so I can review a day's work in 5 minutes.
- *As a dev*, an independent agent runs my tests and a security scan after each task, so broken or vulnerable code never silently accumulates.
- *As a dev*, if the agent tries to edit a file outside the current task's declared scope, the edit is **blocked before it happens** — I find out from a clear message, not from a surprised `git diff` a week later.
- *As a team lead*, I open `.thekedar/changes/` and see exactly which agent touched which file and when.
- *As a returning user*, I open a fresh session and the state is already in context before I type anything — session-brief.sh did it for me.
- *As a Cursor/Codex user*, I get the same workflow (minus context isolation) via a generated AGENTS.md.
- *As a project lead scaling the crew*, I scaffold a new specialist agent in one command instead of hand-writing frontmatter.

## 7. Features & Priorities

### Shipped in v1 (F1–F9)

| ID | Feature |
|---|---|
| F1 | Orchestrator skill: plan → build → review → log → commit loop |
| F2 | Planner agent |
| F3 | Doer agent (backend-dev) |
| F4 | 3 reviewer agents (error-checker, security-auditor, frontend-reviewer) |
| F5 | Munshi hook: deterministic per-edit ledger |
| F6 | Per-task changelog with mandatory "NOT changed" section |
| F7 | PROJECT_STATE.md resume protocol |
| F8 | Git checkpoints per task |
| F9 | Idempotent installer with safe settings merge |

### Shipped in v2 (F10–F26) — this release

| ID | Feature | Description |
|---|---|---|
| F10 | **AGENTS.md export** | `export-agents-md.sh` flattens the full crew + workflow into one file for Cursor/Codex/Copilot/Windsurf — generated, not hand-forked |
| F11 | **Context budget guard** | Concrete compact heuristics in SKILL.md §6 (phase close / ~6 tasks / re-reading signal) + session-brief.sh auto-injection |
| F12 | **Drift detector** | `drift-check.sh`: declared Expected files vs actual `git status`, one report line per task, always in the changelog |
| F13 | **`/thekedar-status`** | Exactly-6-line read-only snapshot skill |
| F16 | **Custom crew scaffolder** | `new-agent.sh <name> --doer\|--gate --model <m>` from `agent-template.md`, tool law pre-applied |
| F17 | **Report generator** | `report.sh` → `REPORT.md`: counted (not estimated) stats + full changelog roll-up + git checkpoints |
| F18 | **scope-guard.sh** | PreToolUse fence: blocks writes outside the ACTIVE task's Expected files + Scope additions. The crown jewel — turns P5 from a prompt into a mechanism |
| F19 | **secret-guard.sh** | PreToolUse: blocks writes containing high-confidence secret patterns (AWS/PEM/JWT/GitHub/Slack/Stripe/Anthropic/Google) |
| F20 | **session-brief.sh** | SessionStart: injects PROJECT_STATE + ACTIVE task + latest changelog pointer automatically |
| F21 | **frontend-dev doer** | Dedicated UI specialist (v1 routed UI work through backend-dev) |
| F22 | **9 extended specialists** | test-writer, db-specialist, api-designer, docs-writer, devops-engineer, refactor-specialist, performance-auditor, accessibility-auditor, dependency-auditor — installed via `--full` |
| F23 | **`.thekedar/config.md`** | 7 keys: fix_loop_cap, auto_continue, default_doer_model, enable_performance_auditor, enable_accessibility_auditor, scope_guard, commit_prefix |
| F24 | **Lifecycle scripts** | `uninstall.sh` (clean removal, keeps history), `update.sh` (pull + reinstall), `--full` flag |
| F25 | **doctor.sh** | 18-point health check with LIVE hook self-tests, not just file-existence checks |
| F26 | **phase.md + decision-record.md** | Templates for >12-task project phasing and ADRs |

### Deferred (P2 — later)

| ID | Feature |
|---|---|
| F14 | Plugin marketplace packaging (`claude plugin install thekedar@thekedar`) |
| F15 | Agent Teams mode (parallel independent tasks across sessions) |
| — | Mega specialist-catalog expansion (see MEGA_EXPANSION.md) — separate scale-up track |

## 8. Success Metrics

- ⭐ 500 GitHub stars in 90 days (proxy for resonance)
- ≥ 80% of orchestrated tasks pass error-checker on first attempt (self-reported benchmark repo)
- Fresh-session resume works with zero re-prompting in the demo project
- Install-to-first-task < 60 s on macOS/Linux/WSL
- ≤ 1 open "hook broke my session" issue per release (every hook that must never block is fixture-tested for exactly that)
- Zero confirmed scope-guard false-positive reports that couldn't be resolved by a Scope-addition entry

## 9. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Token cost of multi-agent scares users | Adoption | Honest README section; Sonnet defaults for doers/reviewers; reviewers run only per-task, not per-edit |
| Hook bugs block user's tool calls | Trust-killer | munshi/session-brief/drift-check always exit 0; guards (scope/secret) exit 2 ONLY on confirmed hits, fail-open on any doubt |
| scope-guard false-positives on legitimate edits | Frustration, users disable the feature | Fail-open design + advisory mode (`scope_guard: off`) as an escape valve; clear stderr message names the exact fix (Scope addition) |
| Per-edit logging too noisy | Annoyance | Ledger = one line per edit; rich narrative only per task |
| Claude Code API/format changes | Breakage | Formats verified against official docs at build time; drift caught by CI (P1 weekly job, tracked) |
| Over-orchestration on tiny asks | UX | Skill explicitly exempts trivial requests: "do it directly, skip ceremony" |
| Two sessions editing the same repo concurrently | Lost/duplicated work, confusing history | Documented as a known hazard (see TROUBLESHOOTING.md); not solved at the tool layer in v2 |

## 10. Competitive Landscape

- **caveman** — token compression; orthogonal, composes with Thekedar.
- **OpenSpec / spec-kit** — spec-driven planning; Thekedar adds execution discipline, review gates, and automatic records on top of the same philosophy.
- **claude-flow / agent orchestration frameworks** — heavyweight, npm-based, often abandoned. Thekedar's bet: markdown + bash + git = boring, durable, auditable.

Differentiator: **nobody combines** task chunking + mechanically-enforced scope + independent multi-agent review + automatic written records in one zero-dependency install. See [COMPARISON.md](COMPARISON.md) for the honest table.
