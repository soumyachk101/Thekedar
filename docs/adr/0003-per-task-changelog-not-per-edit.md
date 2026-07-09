# ADR 0003 — Per-task changelog, not per-edit narration

**Date:** 2026-07-09 · **Status:** accepted

## Context

Every file edit could, in principle, get a narrative explanation ("changed X because Y"). That would maximize granularity of the written record but costs tokens on every single write and — more importantly — asking a model to narrate its own edit mid-flow changes how it makes the edit.

## Decision

Two separate records at two separate granularities: `munshi.sh` appends a zero-token fact line (time, tool, path) to the ledger on every edit, automatically, via a bash hook. The orchestrator writes one changelog entry (what changed, what was deliberately NOT changed, why, verdicts, drift) per **task**, at the LOG+CHECKPOINT step — after the work is done, not while it's happening.

## Consequences

Easier: edit-level facts are free (bash, not tokens) and complete (nothing is skipped because the model "didn't think it worth mentioning"); the meaningful narrative is written once, at the moment the full picture exists, by the agent best positioned to summarize it (the orchestrator, which saw the whole task's arc). Harder: you cannot ask "why did this specific line change" and get a per-line answer — only per-task. If that granularity is ever needed, the ledger's timestamp + `git log -p` at that time is the fallback.

## Alternatives considered

- **Per-edit narrative changelog entries** — rejected: token cost scales with edit count instead of task count (potentially 10-50x more expensive), and self-narration measurably degrades the edit itself (the model splits attention between doing the work and describing it).
- **No task-level record, ledger only** — rejected: a table of file paths and timestamps answers "what" but never "why" or "what was deliberately left alone" — exactly the P2 gap (no audit trail) this whole project exists to close.
