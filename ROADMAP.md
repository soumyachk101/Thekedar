# Roadmap

Feature IDs reference the [PRD](docs/PRD.md).

## v1.0 — the crew (this release)

- [x] Orchestrator skill with the full state machine (F1)
- [x] planner · backend-dev · error-checker · security-auditor · frontend-reviewer (F2–F4)
- [x] munshi hook: zero-token per-edit ledger, never blocks (F5)
- [x] Per-task changelog with mandatory "NOT changed" section (F6)
- [x] PROJECT_STATE.md resume protocol (F7)
- [x] Git checkpoints per task (F8)
- [x] Idempotent installer with safe settings merge (F9)

## v1.x — fast follows

- [ ] **F10 · AGENTS.md export** — `bash scripts/export-agents-md.sh` generates a single-context workflow file for Cursor / Codex / Copilot / Windsurf
- [ ] **F12 · Drift detector** — post-task script: `git diff --name-only` vs the task's Expected files (+ Scope additions); orchestrator flags out-of-scope edits in the changelog
- [ ] **F13 · `/thekedar-status`** — one-shot status from STATE + ledger + git log
- [ ] **F11 · Context guard tuning** — smarter "safe point to compact" heuristics
- [ ] `.thekedar/config.md` — fix-loop cap, model overrides, reviewer opt-outs
- [ ] Hook test suite in CI + weekly docs-drift check against Claude Code format pages

## v2 — the big site

- [ ] **F14 · Plugin packaging** — `claude plugin install thekedar@thekedar`
- [ ] **F15 · Agent Teams mode** — independent tasks run in parallel sessions with worktree isolation (waits for the feature to leave experimental)
- [ ] **F16 · Custom crew** — `bash scripts/new-agent.sh db-migrator` scaffolds a new specialist from a template
- [ ] **F17 · Report generator** — ledger + changelogs → single HTML/PDF project report
- [ ] i18n personalities — the crew reports in your language (Hindi first, obviously 🇮🇳)

## Explicit non-goals

No SaaS, no telemetry, no database, no npm dependency tree. Markdown + bash + git, forever. If a feature can't survive that constraint, it doesn't ship.

Have an idea? Open an issue → see [CONTRIBUTING.md](CONTRIBUTING.md).
