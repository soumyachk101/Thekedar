# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/) (breaking = any change to the task/PROJECT_STATE/changelog/config file contracts or hook I/O, per CONTRIBUTING.md).

This file is maintained by Thekedar's own workflow discipline — every entry below traces to a real phase commit, not a guess after the fact.

## [Unreleased]

### Fixed

**Distribution — the whole catalog now actually ships:**
- `.claude-plugin/plugin.json` registered only `core/` and `extended/`, so 94 of the 109 catalogued agents (`languages`, `frameworks`, `domains`, `ops`, `reviewers`) existed on disk, in the catalog, and in the docs, but never reached a single user. All 7 category directories are now listed.
- `install.sh` / `uninstall.sh` hardcoded the 15 agent names as shell strings and were structurally incapable of installing more. Both now derive the roster from `catalog/agents.psv` at run time, so a new catalog row ships without touching either script. New `install.sh --all` installs every category (`--full` still means core + extended); `update.sh` passes the flag through. The installer refuses a no-op install if the catalog resolves 0 agents.
- `uninstall.sh` now sweeps every category, so it can never lag behind what a newer installer placed.

**Docs drift:**
- README, `index.html`, `docs/TRD.md`, `docs/AGENTS-GUIDE.md` and `INSTALL.md` claimed a 15-agent crew while `catalog/INDEX.md` claimed 109. Corrected to 109 with the 15-agent default install called out explicitly. Historical records (ADRs, BLUEPRINT, shipped changelog entries) left as written.
- `ROADMAP.md` still listed Phases 12–16 as unstarted — the knowledge packs (50) and the agent library (109) have shipped. Phase 17 (integrations) is correctly marked outstanding: `catalog/integrations.psv` is still header-only.

**Landing page:**
- Deleted `thekedar-docs.html` — a byte-for-byte duplicate of `index.html` (80 KB, one word apart, linked from nowhere) that would have drifted on the next edit.
- Added `og:image` (new `assets/og-image.jpg`, 1200×630), `twitter:card`, `og:site_name`, canonical URL, `robots` meta, favicon, and `SoftwareApplication` JSON-LD. Link previews were previously bare text cards. Added `robots.txt` + `sitemap.xml`.
- Removed `maximum-scale=1.0, user-scalable=no` from the viewport — it blocked pinch-zoom (WCAG 1.4.4).
- Every doc now has its own URL (`/#doc-<key>`): deep-linkable, shareable, and the back button walks doc history. Sidebar buttons, the mobile `<select>`, and the nav/footer links all stay in sync.
- FontAwesome loads via `media="print"`/`onload` swap so it no longer blocks first paint; `<noscript>` fallback retained.
- Added a `prefers-reduced-motion` block (WCAG 2.3.3), `aria-label`/`aria-expanded`/`aria-controls` on the mobile menu button, `aria-hidden` on all 36 decorative icons, and the standard `background-clip` alongside its `-webkit-` prefix.

**CI:**
- `ci.yml` and `shellcheck.yml` only triggered on `main`, so every other branch — including the one this work happened on — ran zero checks. Both now run on all branches and all PRs, with a `concurrency` group so a PR from an in-repo branch doesn't run twice.

### Changed

- `catalog/*.tsv` → `catalog/*.psv`. The files were pipe-delimited all along; the `.tsv` extension silently broke `cut -f`, `awk -F'\t'`, and any spreadsheet import. All references updated; generated docs regenerated.

## [2.0.0] — 2026-07-09

### Added

**Guard-rail layer (the headline change):**
- `scope-guard.sh` — PreToolUse hook that mechanically blocks writes outside the ACTIVE task's declared Expected files / Scope additions. Fail-open on any doubt; advisory mode via `scope_guard: off`. Closes the gap where v1's "NOT in scope" fence was text a doer could still cross under context pressure.
- `secret-guard.sh` — PreToolUse hook blocking writes containing high-confidence secret patterns (AWS, PEM, JWT, GitHub, Slack, Stripe, Anthropic, Google). Scans only the content being written, never the whole event, to avoid false positives on removals.
- `session-brief.sh` — SessionStart hook auto-injecting PROJECT_STATE + active-task + latest-changelog pointers, making resume genuinely zero-prompt.
- `drift-check.sh` — orchestrator-invoked audit comparing declared scope vs actual `git status`; its `DRIFT:` line lands in every changelog.

**Crew, doubled:**
- `frontend-dev` — dedicated UI doer (v1 routed UI work through backend-dev).
- 9 extended specialists (`install.sh --full`): test-writer, db-specialist, api-designer, docs-writer, devops-engineer, refactor-specialist, performance-auditor, accessibility-auditor, dependency-auditor.
- Orchestrator skill routes tasks to the matching specialist by nature of the work; 3 new command skills — `/thekedar-status` (6-line snapshot), `/thekedar-report`, `/thekedar-plan` (plan-and-stop).

**Config & lifecycle:**
- `.thekedar/config.md` — 7 keys (fix_loop_cap, auto_continue, default_doer_model, enable_performance_auditor, enable_accessibility_auditor, scope_guard, commit_prefix).
- `install.sh --full` flag, `uninstall.sh`, `update.sh`.
- `scripts/doctor.sh` — 18-point health check with live hook self-tests, not just file-existence checks.
- `scripts/export-agents-md.sh` — generates `AGENTS.md` for Cursor/Codex/Copilot/Windsurf from the actual agent files.
- `scripts/new-agent.sh` — scaffolds a custom agent with the doer/gate tool law pre-applied.
- `scripts/report.sh` / `scripts/stats.sh` — counted-fact project reports.
- Templates: `config.md`, `agent-template.md`, `decision-record.md`, `phase.md`; `task.md` gained Risk + Estimated size; `PROJECT_STATE.md` gained a Phases section; `changelog-entry.md` gained a drift-check line.

**Docs & infra:**
- Full `docs/` rebuild: expanded PRD/TRD/ARCHITECTURE, new WORKFLOW/AGENTS-GUIDE/HOOKS-GUIDE/COMMANDS/CUSTOMIZATION/TROUBLESHOOTING/FAQ/COMPARISON/BENCHMARKS, 7 ADRs.
- `.github/`: issue templates (bug/feature/agent-improvement), PR template with the dogfood-evidence rule, `ci.yml` (tests, ubuntu+macos) and `shellcheck.yml` workflows.
- `CODE_OF_CONDUCT.md`, `SECURITY.md`.
- Test suite grew from hook fixtures only to 7 suites: munshi, scope-guard, secret-guard, session-brief, drift-check, installer (fresh/idempotent/merge/--full/uninstall), export-agents.

### Changed

- Agents restructured into `.claude/agents/{core,extended,custom}/` (recursive scan) from a flat directory.
- `install.sh` now installs 5 hooks (was 1), 4 skills (was 1), and merges `SessionStart`+`PreToolUse`+`PostToolUse` wiring (was `PostToolUse` only).
- CONTRIBUTING.md's hook rule widened from "munshi never blocks" to "3 hooks never block, 2 guards fail open on doubt."

### Fixed

- **Path-traversal bypass in `scope-guard.sh` and `secret-guard.sh`** (found and fixed across two rounds of pre-release security review, before this tag — never shipped). Round 1: the guards matched the raw, unresolved `file_path` against their allow/exclude lists, so `src/../outside/x` slipped a `src/*` scope entry and `fixtures/../src/prod.env` slipped the secret-scanner's `fixtures/*` exclusion (shell glob `*` matches a literal `..`). Round 2: the lexical canonicalizer added in round 1 split the path with an unquoted `set -- $_p`, which glob-**expanded** a literal segment like `s*` against the process cwd — matching a real `src/` and reopening the same bypass through a different mechanism. Final fix: both guards (and drift-check.sh's shared helper) canonicalize the path lexically *with pathname expansion disabled* (`set -f` around the split) before any comparison. Regression tests cover both `..`-traversal and glob-metacharacter (`*`, `[...]`) segments. This closes the **lexical** traversal holes; symlink resolution is an explicit, documented non-goal (reaching a symlink escape requires a Bash call, which is already an unguarded write-anywhere path — see the threat-model section in [SECURITY.md](SECURITY.md) and [ADR-0006](docs/adr/0006-scope-guard-as-pretooluse.md)). A third review round confirmed no remaining single-tool-call bypass.
- `munshi.sh`: redirect-order bug where a failed ledger write's own error message could leak to stderr instead of being fully silenced.
- `scope-guard.sh`'s config parser: `scope_guard: off  # comment` was being read as the literal string `off#comment` and silently ignored — now strips trailing comments before comparing.
- `drift-check.sh`: replaced an `A && B || C` idiom (SC2015 — `C` could run even when `A` held) with an explicit `if`, caught by the shellcheck CI job.

## [1.0.0] — 2026-07-09

Initial release — the crew, the ledger, the loop.

### Added

- `thekedar` orchestrator skill: plan → build one task → review gates → log → git checkpoint state machine.
- 5 core agents: planner, backend-dev, error-checker, security-auditor, frontend-reviewer.
- `munshi.sh` — PostToolUse hook, deterministic per-edit ledger, always exits 0.
- Task / PROJECT_STATE / changelog-entry templates with the mandatory "what was deliberately NOT changed" section.
- `install.sh` — idempotent installer with safe `settings.json` merge (backs up differing files, never silently overwrites).
- `PRD.md`, `TRD.md`, `ARCHITECTURE.md`.
