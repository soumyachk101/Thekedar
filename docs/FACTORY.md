# The Factory — how the crew scales without rotting

Thekedar's crew is not hand-maintained as a pile of markdown files. It is **catalog-driven**: one row per agent in a data file, generators that turn rows into files, and validators that refuse to let the two drift apart. This is the machinery that lets the agent library grow toward hundreds of specialists (see [MEGA_EXPANSION_1.md](../MEGA_EXPANSION_1.md)) while staying coherent — nobody hand-writes a thousand files and keeps them consistent; you build a factory that produces them and a gate that keeps them honest.

## The one rule

> Every agent file must trace back to **(a)** a catalog row, **(b)** a golden pattern it follows, and **(c)** a validator that passes it. No orphan files, ever — in either direction.

`validate-all.sh` enforces the bidirectional half mechanically: a catalog row with no file fails; a file with no catalog row fails.

## The pieces

```
catalog/
├── agents.tsv          ← ONE row per agent: name|category|type|tools|model|krefs|trigger
├── knowledge.tsv       ← the shared-brain packs (built in the Mega expansion)
├── integrations.tsv    ← per-tool adapters (built in the Mega expansion)
└── INDEX.md            ← GENERATED master index, grouped by category

scripts/factory/
├── gen-agent.sh         ← catalog row → valid .md skeleton (Claude fills the body)
├── gen-agent-docs.sh    ← every agent's frontmatter → docs/agents/<name>.md (automated)
├── gen-index.sh         ← catalog → catalog/INDEX.md
├── validate-agents.sh   ← HARD GATE (frontmatter, name==file, gates read-only,
│                           MUST-BE-USED, required sections, refs resolve, 0 orphans)
├── validate-knowledge.sh← pack quality (≥40 lines, referenced by ≥1 agent)
├── validate-links.sh    ← every relative Markdown link resolves
└── validate-all.sh      ← runs all of the above; CI gates on it
```

## The generation loop

1. **Add rows** to `catalog/agents.tsv`.
2. **Write one golden agent per category** by hand, reviewed hard — the quality anchor.
3. **Generate the rest in small batches**: `gen-agent.sh <name>` produces a valid skeleton (frontmatter filled from the row, `MUST BE USED when <trigger>` already in place); a Claude Code session fills the body following the category's golden file.
4. **Gate every batch**: `validate-all.sh` must pass, then commit. A batch that fails is fixed before the next one starts — never proceed dirty.
5. **Regenerate derived files**: `gen-index.sh` + `gen-agent-docs.sh`. Humans never edit generated output (each carries a `GENERATED` header); the generators are deterministic (re-running produces no diff — a test asserts this).

Each batch is a fresh, scoped session with state on disk between batches — which is to say, the factory is built and run *using Thekedar's own methodology*. Thekedar scales Thekedar.

## Why TSV + bash and not a real build tool

Same bet as the rest of the project (see [ADR-0001](adr/0001-markdown-as-the-interface.md)): a pipe-delimited data file and a few bash scripts have zero dependencies, diff readably, and will still run in five years. The validators are the load-bearing part, not the generators — a generator that produces a bad file is caught by the gate; a gate that lets a bad file through is the only real failure, so that's where the rigor goes.

## Current state

**21 agents** (6 core + 9 extended + **6 `languages/` specialists**: python-dev, typescript-dev, go-dev, rust-dev, java-dev, ruby-dev), 21 catalog rows, 0 orphans, `validate-all` green in CI. `python-dev` is the hand-written **golden** language specialist the others follow.

**Knowledge library: 40 packs**, ≥60 lines each, 0 orphans — `security/` (14), `pitfalls/` (8, the AI-hallucination-trap differentiator), `patterns/` (12), `review-checklists/` (6), all cited by the right agents/gates.

The orchestrator routes to a `<lang>-dev` specialist when the task's stack matches (SKILL.md §2 stack-specialist routing; tasks may carry an optional `Stack tags:` line). The remaining `languages/` (12 more), `frameworks/`, `domains/`, `ops/`, `reviewers/` agent categories and `best-practices/`/CWE knowledge are populated batch by batch on this foundation — the mechanism is proven (`gen-agent.sh` → fill body per the category golden → `validate-all` gate → commit).
