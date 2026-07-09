# FAQ

## What does this actually cost in tokens?

Estimate 2–4× a raw single-session request for orchestrated work (see BENCHMARKS.md for methodology). Where it goes: a planner pass up front, then per task roughly one doer invocation + 2 gate invocations (error-checker + security-auditor, always) + conditional gates when relevant files/flags apply. Reviewers fire **once per task**, not per edit — that's the single biggest cost control. `--full` (9 extra specialists) doesn't multiply cost proportionally; most tasks still only route through 2–3 agents total, just better-matched ones.

## When should I NOT use this?

- **Throwaway scripts, one-off queries, single-file tweaks.** The orchestrator's own triage rule skips ceremony for anything under ~30 lines / one file — say so and it just does the thing.
- **Exploratory/uncertain work** where you're still figuring out what you even want. Planning locks in a shape; if you don't know the shape yet, talk it through first, orchestrate once you do.
- **Tiny personal projects you'll never revisit.** The whole value proposition is the paper trail and review gates paying off over time and across sessions — if there's no "later," there's less to gain.

## How is this different from caveman?

Orthogonal, not competing — they compose. caveman compresses *how* the model talks (terse mode, fewer tokens per response). Thekedar structures *what* work happens and in what order (plan → scoped build → independent review → written record). Nothing stops you running Thekedar's crew in caveman mode simultaneously; reviewer verdicts are already terse by format, and caveman would compress the orchestrator's own narration further.

## Is there a single-agent / no-subagent-isolation mode?

Yes — `export-agents-md.sh` generates an `AGENTS.md` that flattens the whole crew and workflow into one file for tools without Claude Code's subagent isolation (Cursor, Codex CLI, Copilot, Windsurf). One context plays every role in sequence, following the same plan→build→review→log loop. It's honestly weaker: the "reviewer" role shares the doer's memory and blind spots in that mode, since there's no fresh context wall between them. Still beats no review and produces the identical file trail (tasks, ledger, changelogs, PROJECT_STATE). See COMPARISON.md.

## Does scope-guard mean the AI literally cannot go rogue?

It means the AI cannot **silently** touch a file outside the current task's declared scope while a task is ACTIVE — the write is rejected at the tool-call layer before it happens, not caught after the fact in review. It does not prevent a determined agent from adding a bogus `## Scope addition` entry and then editing anyway (the guard checks that the entry exists, not that the reason is honest) — that's still a review-time and human-attention problem, same as any other bad reasoning. The guard closes the "oops, forgot the fence was just text" failure mode, not the "the model actively decided to lie about its reason" one.

## What happens if I don't have `jq` or `python3`?

Everything still works, just with reduced precision in edge cases. Hooks fall back through jq → python3 → grep-based extraction for the ledger and scope-guard's path parsing. secret-guard specifically requires jq or python3 to safely isolate written content from the raw event (a plain grep here risks matching `old_string`/unrelated fields and either missing real secrets or blocking on removed ones) — without either, it fails open rather than guess. The installer's settings.json merge also needs python3; without it, the installer prints the JSON block for you to paste in by hand.

## Can I use this with a language/framework Thekedar doesn't have a specialist for?

Yes — the core crew (`backend-dev`, `frontend-dev`) isn't language-specific; it reads and mirrors whatever conventions already exist in your codebase. The 9 extended specialists (`--full`) are role-based (db, devops, docs, refactor, test, api-design), not language-based, so the same applies there too. If you want a genuinely dedicated specialist for one ecosystem, scaffold one with `new-agent.sh` (see CUSTOMIZATION.md).

## Why markdown and bash instead of a real database/daemon?

Durability and inspectability. A markdown file survives every tool migration, every Claude Code version bump, and opens in literally anything. A daemon is one more thing to keep running, one more thing to debug when it silently dies. See [ADR-0001](adr/0001-markdown-as-the-interface.md) for the full reasoning, and the project's explicit non-goals (PRD §4): no SaaS, no telemetry, no database, ever.

## Does the munshi ledger log file *contents*, or just paths?

Just paths, tool name, and timestamp — by design (see TRD §5). The ledger is safe to commit even in a repo with sensitive business logic; it never captures what changed, only that something did.
