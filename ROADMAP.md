# Roadmap

Feature IDs reference the [PRD](docs/PRD.md).

## v1.0 — the crew (shipped)

- [x] Orchestrator skill with the full state machine (F1)
- [x] planner · backend-dev · error-checker · security-auditor · frontend-reviewer (F2–F4)
- [x] munshi hook: zero-token per-edit ledger, never blocks (F5)
- [x] Per-task changelog with mandatory "NOT changed" section (F6)
- [x] PROJECT_STATE.md resume protocol (F7)
- [x] Git checkpoints per task (F8)
- [x] Idempotent installer with safe settings merge (F9)

## v2.0.0 — the guard-rail layer (shipped, this release)

- [x] **F18 · scope-guard.sh** — PreToolUse fence, mechanically enforced scope, fail-open by design
- [x] **F19 · secret-guard.sh** — PreToolUse high-confidence secret scan
- [x] **F20 · session-brief.sh** — SessionStart auto-injection, zero-prompt resume
- [x] **F10 · AGENTS.md export** — `export-agents-md.sh`, generated from the real agent files
- [x] **F12 · Drift detector** — `drift-check.sh`, one honest line per changelog
- [x] **F13 · `/thekedar-status`** — exactly-6-line read-only snapshot
- [x] **F11 · Context guard tuning** — concrete compact heuristics in SKILL.md §6
- [x] **F21 · frontend-dev doer** — dedicated UI specialist
- [x] **F22 · 9 extended specialists** — test-writer, db-specialist, api-designer, docs-writer, devops-engineer, refactor-specialist, performance-auditor, accessibility-auditor, dependency-auditor
- [x] **F23 · `.thekedar/config.md`** — fix-loop cap, model default, reviewer opt-ins, scope-guard mode, commit prefix
- [x] **F16 · Custom crew scaffolder** — `new-agent.sh`
- [x] **F17 · Report generator** — `report.sh` / `stats.sh` (markdown; HTML variant still open, see below)
- [x] **F24 · Lifecycle scripts** — `uninstall.sh`, `update.sh`, `install.sh --full`
- [x] **F25 · doctor.sh** — health check with live hook self-tests
- [x] Full docs suite (12 guides + 7 ADRs) and GitHub infra (issue/PR templates, CI, shellcheck)
- [x] `examples/demo-todo-app` — real, unedited generated `.thekedar/` output

## v2.x — fast follows

- [x] **F14 · Plugin packaging** — `claude plugin marketplace add soumyachk101/Thekedar` → `claude plugin install thekedar@thekedar`; SessionStart bootstrap creates `.thekedar/` on first run so plugin mode matches the script install
- [ ] **F15 · Agent Teams mode** — parallel independent tasks across sessions (waits for the feature to leave experimental)
- [ ] Windows-native (PowerShell) hook variants — currently Git Bash/WSL only
- [ ] Real benchmark runs against the [BENCHMARKS.md](docs/BENCHMARKS.md) methodology — no numbers published yet
- [ ] Concurrent-session safety — two sessions on one Thekedar project currently race (see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md))
- [ ] Hook test suite already in CI (this release) — next: weekly docs-drift check against Claude Code's own format pages
- [ ] HTML/PDF report variant (report.sh currently emits markdown only)
- [ ] i18n crew personalities — the crew reports in your language (Hindi first, obviously 🇮🇳)

## v3 — the big site (see [MEGA_EXPANSION_1.md](MEGA_EXPANSION_1.md))

A separate, later scale-up track: a catalog-driven factory generating ~120 language/framework/domain/ops specialists, a shared knowledge-pack library (security, best-practices, AI-hallucination-pitfalls, patterns), 15 tool integrations, and a validated 800–1200-file collection — built the same way this project builds anything, in small verified batches, never hand-written wholesale.

- [x] **Phase 11 · The factory** — `catalog/agents.tsv` + `scripts/factory/` (generators + validators) + `validate-all.sh` coherence gate in CI. Foundation laid: 15 agents catalogued, 0 orphans, `gen-agent.sh` proven. See [docs/FACTORY.md](docs/FACTORY.md).
- [ ] **Phase 12-13 · Knowledge packs** — security (OWASP/CWE), best-practices, the AI-hallucination-pitfalls pack (the real differentiator), review-checklists, patterns
- [ ] **Phase 14-16 · Agent library** — languages, frameworks, domains, ops, reviewers — golden file per category, then batches of 10, validated per batch
- [ ] **Phase 17-20 · Integrations, skills, examples, docs auto-gen, v3.0.0**

The catalog scale-up rides on top of the shipped v2 core rather than replacing it — growing a collection on an unproven engine would be building on sand.

## Explicit non-goals

No SaaS, no telemetry, no database, no npm dependency tree. Markdown + bash + git, forever. If a feature can't survive that constraint, it doesn't ship.

Have an idea? Open an issue → see [CONTRIBUTING.md](CONTRIBUTING.md).
