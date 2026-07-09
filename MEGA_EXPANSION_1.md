# THEKEDAR — MEGA EXPANSION (v3 "Collection Scale")

> **Plugs into BLUEPRINT.md.** Build Phases 0–10 from BLUEPRINT.md first (the core product).
> Then this file adds Phases 11–20, scaling the repo from ~90 files to **800–1200+ files**
> the way real large collections do it: **catalog-driven generation + golden patterns +
> automated validation.** Nobody hand-writes 1000 files. You build a factory that
> produces them consistently, and validators that keep all 1000 coherent.

---

## §0 — THE SCALING LAW (read this or the repo becomes landfill)

Big repos earn stars two ways:
1. **Sharp product** (caveman: one idea, small repo, 86k stars)
2. **Comprehensive collection** (agent libraries: 100–300 agents, people bookmark them as a resource)

Thekedar Mega = **both**: the workflow engine (core) + the biggest specialist crew catalog
(collection). The rule that keeps 1000 files valuable instead of filler:

> **Every generated file must trace back to (a) a catalog row, (b) a golden pattern it
> follows, and (c) a validator that passes it.** No orphan files. Ever.

File math at full catalog (approximate, grows with catalog):

| Block | Files |
|---|---|
| Core product (BLUEPRINT.md Phases 0–10) | ~90 |
| Agent library: ~120 specialists across 6 categories | ~120 |
| Per-agent doc pages (auto-generated) | ~120 |
| Knowledge packs (security, best-practices, pitfalls, checklists, patterns) | ~110 |
| Integrations: 15 tools × (adapter + rules + install doc) | ~45 |
| Skills: 8 skill folders × (SKILL + REFERENCE + EXAMPLES) | ~24 |
| Templates: task types + project starters | ~20 |
| i18n crew-strings + translated READMEs (8 languages) | ~24 |
| Examples: 4 full demo projects with real .thekedar/ output | ~100 |
| Cookbook recipes (how-to guides) | ~30 |
| Tests: fixtures × hooks × scenarios + validators' own tests | ~80 |
| Factory: catalog data, generators, validators | ~15 |
| CI workflows, meta docs, indexes | ~20 |
| **Total** | **~800, scaling past 1000 as the catalog grows** |

---

## §1 — THE FACTORY (build this FIRST — Phase 11)

```
catalog/
├── agents.tsv            ← ONE row per agent: name|category|type|tools|model|triggers|knowledge-refs
├── knowledge.tsv         ← name|category|summary|applies-to
├── integrations.tsv      ← tool|mechanism(rules-file/plugin/skill)|config-path
└── INDEX.md              ← human-readable master index (generated)

scripts/factory/
├── gen-agent.sh          ← catalog row + golden pattern → .claude/agents/<cat>/<name>.md skeleton
│                            (Claude Code fills the body; frontmatter comes from the row)
├── gen-agent-docs.sh     ← frontmatter of every agent → docs/agents/<name>.md (fully automated)
├── gen-index.sh          ← regenerates catalog/INDEX.md + README crew tables
├── validate-agents.sh    ← HARD GATE: valid YAML frontmatter; name matches filename; category
│                            valid; gates have NO Write/Edit; description starts "MUST BE USED";
│                            body has required sections (Process / Verdict|Output / Rules);
│                            every knowledge-ref resolves to a real file
├── validate-knowledge.sh ← required sections per pack type; no empty stubs (<30 lines = FAIL)
├── validate-links.sh     ← every relative link in every .md resolves
└── validate-all.sh       ← runs everything; CI calls this; non-zero on any failure
```

**The generation loop (this is how 1000 files stay sane):**

1. Add rows to `catalog/agents.tsv`.
2. Write ONE **golden agent** per category by hand, reviewed hard (these are the quality anchors).
3. Claude Code generates the rest **in batches of 10**: `gen-agent.sh` makes the skeleton from
   the catalog row, Claude writes the body following the category's golden file.
4. After every batch: `validate-agents.sh` must pass, then commit. Batch fails → fix batch,
   never proceed dirty.
5. `gen-agent-docs.sh` + `gen-index.sh` regenerate docs and indexes. Humans never edit
   generated docs (header comment marks them).

Each batch is a fresh, scoped Claude Code session with state on disk between batches —
you are literally using Thekedar's own methodology to build Thekedar Mega. That's the README story.

---

## §2 — AGENT LIBRARY (~120 specialists) — Phases 14–16

Directory: `.claude/agents/<category>/<name>.md` (Claude Code scans recursively; only the
`name:` field matters for identity, so keep names globally unique).

**languages/ (18):** python-dev, typescript-dev, javascript-dev, go-dev, rust-dev, java-dev,
kotlin-dev, swift-dev, cpp-dev, c-dev, csharp-dev, php-dev, ruby-dev, dart-dev, scala-dev,
elixir-dev, bash-dev, sql-dev

**frameworks/ (26):** react-specialist, nextjs-specialist, vue-specialist, nuxt-specialist,
svelte-specialist, angular-specialist, astro-specialist, remix-specialist, django-specialist,
fastapi-specialist, flask-specialist, rails-specialist, laravel-specialist, spring-specialist,
express-specialist, nestjs-specialist, graphql-specialist, prisma-specialist, drizzle-specialist,
tailwind-specialist, react-native-specialist, flutter-specialist, electron-specialist,
redux-state-specialist, htmx-specialist, wordpress-specialist

**domains/ (18):** ml-engineer, data-engineer, llm-integrator, prompt-engineer, blockchain-dev,
game-dev, embedded-dev, mobile-architect, desktop-dev, cli-toolsmith, scraping-specialist,
auth-systems, payments-integrator, realtime-systems, search-specialist, caching-specialist,
queue-systems, i18n-specialist

**ops/ (12):** kubernetes-engineer, terraform-engineer, aws-architect, gcp-architect,
docker-specialist, ci-cd-engineer, monitoring-engineer, incident-responder, sre-reviewer,
release-manager, backup-recovery, cost-auditor

**reviewers/ (20):** architecture-reviewer, api-contract-reviewer, test-coverage-auditor,
docs-auditor, license-auditor, seo-auditor, code-style-auditor, complexity-auditor,
error-handling-auditor, logging-auditor, python-reviewer, typescript-reviewer, go-reviewer,
rust-reviewer, java-reviewer, sql-reviewer, react-reviewer, api-security-reviewer,
data-privacy-auditor, config-auditor

**core/ + extended/ (15):** from BLUEPRINT.md, unchanged — they run the workflow;
specialists above are *routed to* by the orchestrator based on the task's stack tags.

**Frontmatter law (validator-enforced):** doers get `Read, Write, Edit, Bash, Grep, Glob`;
reviewers/auditors get `Read, Grep, Glob, Bash` only; model per catalog (default sonnet,
haiku for light auditors); every description = "MUST BE USED when <trigger>...".
Every specialist body cites its `knowledge/` refs from the catalog row.

**Orchestrator upgrade (small SKILL.md patch, Phase 16):** tasks gain an optional
`Stack tags:` line; the thekedar skill routes doer work to the matching specialist if one
exists, else falls back to backend-dev/frontend-dev. Reviewer set likewise extends by tag.

---

## §3 — KNOWLEDGE PACKS (~110 files) — Phases 12–13

The agents' shared brain. Referenced by path from agent bodies; validated by validate-knowledge.sh.

```
knowledge/
├── security/            (~36) owasp/a01..a10.md (one deep file each: what, detect-greps,
│                        exploit scenario, fix patterns) · cwe-top/cwe-79.md, cwe-89.md,
│                        … top 25 · secrets-patterns.md · authz-checklist.md ·
│                        supply-chain.md · crypto-rules.md
├── best-practices/      (~26) one per framework in the catalog: conventions, project
│                        structure, testing approach, deploy notes
├── pitfalls/            (~18) per stack: **known AI-hallucination traps** — APIs models
│                        invent, deprecated patterns models still emit, version confusions.
│                        (This pack is a genuine differentiator — nobody ships this.)
├── review-checklists/   (~20) per language + per dimension (perf, a11y, error-handling,
│                        logging, testing, API design)
└── patterns/            (~12) api-design.md, error-handling.md, migrations.md,
                         feature-flags.md, pagination.md, idempotency.md, rate-limiting.md,
                         caching-strategies.md, background-jobs.md, webhooks.md,
                         file-uploads.md, observability.md
```

Quality bar: every knowledge file ≥ 60 substantive lines, has Detect / Fix / Verify sections
where applicable, and is cited by ≥ 1 agent (validator checks both directions — no orphan
knowledge, no dangling refs).

---

## §4 — INTEGRATIONS (15 tools, caveman-style) — Phase 17

```
integrations/<tool>/
├── README.md            ← install + what degrades (no subagent isolation outside Claude Code)
├── rules file           ← .cursorrules / AGENTS.md / config per tool, generated by
│                          export-agents-md.sh with tool-specific header
└── verify.md            ← 3-step "is it working" check
```

Tools: cursor, codex-cli, copilot, windsurf, cline, gemini-cli, opencode, zed, aider,
continue, roo-code, amazon-q, jetbrains-ai, void, trae. All share one generator —
15 tools ≠ 15 codebases, it's 1 generator + 15 thin configs. Install matrix table in
INSTALL.md, caveman-style.

## §5 — SKILLS, i18n, EXAMPLES, COOKBOOK — Phases 18–19

**skills/ (8 folders × 3 files):** thekedar, thekedar-status, thekedar-report, thekedar-plan
(core four) + thekedar-onboard (analyze an EXISTING codebase → generate STATE + backlog),
thekedar-audit (full-project review sweep by all auditors → report), thekedar-bugfix
(issue text → repro task → fix pipeline), thekedar-release (changelog roll-up → version bump
→ tag checklist). Each folder: SKILL.md + REFERENCE.md + EXAMPLES.md.

**i18n/ (8 langs):** hi, en, es, pt, zh, ja, de, fr → crew-strings.md (status/report phrases
the orchestrator uses) + README.<lang>.md. Config key `language: hi` switches crew reports.
Hindi first. 🇮🇳

**examples/ (4 × ~25 files):** demo-todo-api (backend), demo-dashboard (frontend-heavy →
frontend-reviewer + a11y in action), demo-cli-tool (Go/Rust specialist routing), demo-legacy-onboard
(thekedar-onboard on a messy repo). Each = REAL generated .thekedar/ output: tasks, ledgers,
changelogs, STATE. This is the proof section visitors screenshot.

**docs/cookbook/ (~30 recipes):** "Add a custom specialist in 5 min", "Run security-only audits
nightly via CI", "Thekedar + caveman together", "Monorepo setup", "Pin models per agent",
"Disable gates for prototyping", "Migrate from v1", etc.

## §6 — CI AT SCALE — Phase 20

Workflows: ci.yml (tests/run-all.sh, ubuntu+macos) · validate.yml (factory validate-all.sh —
the 1000-file coherence gate) · links.yml (validate-links.sh) · markdown-lint.yml ·
shellcheck.yml · release.yml (tag → zip artifact + checksum). Badges for all in README.

---

## §7 — PHASES 11–20 (continue after BLUEPRINT.md Phase 10)

**P11 — Factory.** catalog TSVs (seed: 30 agent rows), all gen-* and validate-* scripts + their
tests. ✅ validate-all.sh green on the core repo; gen-agent.sh produces a valid skeleton.

**P12 — Knowledge: security.** owasp/ + cwe-top/ + the 4 standalone files. ✅ validate-knowledge green; every file ≥60 lines.

**P13 — Knowledge: the rest.** best-practices, pitfalls, review-checklists, patterns. ✅ same gate; pitfalls pack has ≥15 real hallucination traps with examples.

**P14 — Agents: languages.** Golden file: python-dev (hand-written, hard-reviewed). Then batches
of 10 via factory. ✅ validate-agents green; every agent cites resolving knowledge refs.

**P15 — Agents: frameworks + domains.** Golden: react-specialist, ml-engineer. Batches of 10.
✅ same gates; catalog rows = files on disk (no drift).

**P16 — Agents: ops + reviewers + routing.** Golden: kubernetes-engineer, architecture-reviewer.
Orchestrator SKILL.md stack-tag routing patch. ✅ reviewers all read-only (validator proves it);
routing works in a scratch project.

**P17 — Integrations.** export generator upgrade + 15 tool folders. ✅ each rules file generated,
not hand-forked; verify.md steps accurate.

**P18 — Skills + i18n.** 4 new skill folders, REFERENCE/EXAMPLES for all 8; i18n packs; config
`language:` support. ✅ /thekedar-onboard produces a sane backlog on a sample repo.

**P19 — Examples + cookbook.** Run Thekedar itself to generate the 4 demos' .thekedar/ output
(real, not mocked); 30 cookbook recipes. ✅ demo changelogs have honest NOT-changed sections;
links green.

**P20 — Docs auto-gen + Mega README + release.** gen-agent-docs for all ~120, INDEX.md, README
crew tables (generated), BENCHMARKS run, full validate-all + CI matrix green → tag v3.0.0.
✅ file count report in README ("~N files, 0 orphans — every file traces to catalog+validator").

**Batch rules for Claude Code (add to §4 guardrails of BLUEPRINT.md):**
- Agent/knowledge generation ALWAYS in batches ≤ 10 files, validator after every batch, commit per batch.
- New session per phase (or per 2 batches) — state is on disk; don't cook one giant context.
- Golden files are hand-quality: if a generated file is weaker than its golden, fix or delete it.
- Never pad a file to pass the length validator. Thin content = delete the catalog row instead.

---

## §8 — HONEST FOOTNOTE (rakho dimaag me)

File count impresses for 10 seconds; the validator badge and the pitfalls pack impress forever.
caveman is tiny and has 86k stars; collections are huge and get bookmarked — you're building the
hybrid. Ship core (P0–10) as v2.0 EARLY, start getting users, and grow to Mega (P11–20) as v3.0
in public. A repo that visibly grows every week beats a repo that appears fully formed and stale.
