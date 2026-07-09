# Comparison

Honest, not marketing. If a row makes Thekedar look worse, it stays.

## vs. raw Claude Code (no workflow layer)

| | Raw Claude Code | + Thekedar |
|---|---|---|
| Planning | Ad hoc, in-conversation | Written task files, scoped, before code exists |
| Scope control | Whatever the prompt says | Mechanically enforced (scope-guard.sh blocks at write-time) |
| Review | You, or asking the same context to "check its work" | Independent subagent, fresh context, never saw the implementation reasoning |
| Audit trail | `git log` messages, whatever you happened to write | Automatic ledger (every edit) + per-task changelog (what/why/what-NOT) |
| Resume | Re-explain state each session | session-brief.sh auto-injects PROJECT_STATE at SessionStart |
| Token cost | Baseline | 2–4× (see BENCHMARKS.md) |
| Setup | None | `install.sh`, restart session |
| Best for | Small tasks, exploration, one-offs | Multi-session projects you'll maintain |

Thekedar is strictly more expensive for anything genuinely small — that's why the orchestrator's own first rule is triaging trivial requests straight through, no ceremony.

## vs. OpenSpec / spec-kit

Both are spec-driven-development philosophies: write down what you're building before you build it, in small reviewable chunks. Real overlap.

| | OpenSpec / spec-kit | Thekedar |
|---|---|---|
| Spec format | Structured spec documents | Task files (objective/scope/NOT-scope/acceptance) |
| Execution | You (or your agent) implements against the spec | Specialist subagents implement, one task at a time, routed by task type |
| Enforcement | Spec is a reference document | scope-guard.sh mechanically blocks writes outside declared scope |
| Review | Not prescribed | Built-in: 2 mandatory gates + conditional gates, every task |
| Records | The spec itself | Ledger (automatic) + changelog (per task, includes reviewer verdicts) |

Where Thekedar adds on the same philosophy: execution discipline (who builds it, and what they're allowed to touch) and automatic written records on top of planning. Where spec-kit-style tools can be lighter: if you just want the spec artifact and plan to implement by hand or with a simpler loop, the full crew + gates is more machinery than you need.

## vs. claude-flow / heavyweight agent-orchestration frameworks

| | Typical orchestration framework | Thekedar |
|---|---|---|
| Runtime deps | npm/pip tree, often substantial | Zero — bash + git, `jq`/`python3` used-if-present |
| Persistence | Often a database or custom state store | Markdown files, git-tracked |
| Failure mode | Framework bug/abandonment breaks your workflow | Every file still just opens in a text editor even if Thekedar itself vanished |
| Learning curve | Framework-specific APIs/concepts | Read the markdown; it's the whole interface |
| Maturity risk | Many such frameworks go unmaintained | Explicit non-goal (PRD §4) to ever need a dependency tree — nothing to abandon-in-place |

The bet, stated plainly: boring and durable beats clever and fragile for something you're trusting with unattended multi-hour edits. Whether that bet is right depends on whether you value framework features (visual dashboards, complex agent topologies) more than longevity and inspectability.

## vs. doing manual code review of AI output

The honest baseline this whole project is measured against. Thekedar's gates catch the mechanical stuff reliably (does it compile, do tests pass, are there obvious secrets/injections) and reduce how much you need to eyeball — but see the README's own "Honest Notes": reviewers can be wrong, and they don't replace your eyes on a final PR. Budget for spot-checking, especially on security-sensitive or judgment-heavy changes.
