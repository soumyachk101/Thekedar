# Benchmarks

**Status: methodology only. No numbers published yet.** Per the project's own non-negotiables (TRD §1, CONTRIBUTING.md): never fabricate benchmark numbers, star counts, or testimonials anywhere in docs. This page exists so the methodology is public and reviewable *before* any number gets attached to it — numbers arrive in a release note once measured, not before.

## What "success" would mean, precisely

Three claims this project makes that are, in principle, measurable:

1. **Fewer hallucinated/broken outputs on multi-hour projects** (PRD G1) — operationalized as: % of tasks that pass error-checker on the first attempt (no fix loop needed), on a fixed benchmark repo, compared to the same tasks attempted in one raw, un-orchestrated session.
2. **Token overhead is 2–4×**, not more (TRD §3.3, README's Honest Notes) — operationalized as: total tokens consumed completing a fixed feature set via Thekedar vs. via a raw single session, same model, same feature set, averaged across ≥3 runs each to smooth variance.
3. **Resume works with zero re-prompting** (PRD G4) — operationalized as: starting a fresh session on a project mid-way through, measuring whether the orchestrator can state the correct current task and continue correctly using only session-brief's auto-injected context, with no user re-explanation.

## Planned methodology

- **Fixed benchmark repo(s):** a small set of representative projects (e.g. a REST API with auth, a small React dashboard) built from an identical starting prompt, once with Thekedar and once without, same underlying model for both arms.
- **First-attempt pass rate:** count tasks where error-checker's first verdict is PASS, divided by total tasks, across a full project build. Reported per-repo, not pooled, since task granularity affects the denominator.
- **Token accounting:** sum of all agent invocations (main session + every subagent call) for the Thekedar arm, vs. total tokens for the raw-session arm attempting the same end result, judged complete by the same acceptance criteria in both arms.
- **Resume test:** deliberately restart the session (simulating `/clear` or a new day) after N tasks, before task N+1 begins, and score whether the very next orchestrator response correctly identifies state without the user supplying it.
- **Runs per condition:** minimum 3, given LLM output variance; report the range, not just a mean.

## What we will NOT do

- Cherry-pick the one run that looks best.
- Compare against a strawman raw-session prompt that wasn't given a fair chance (same underlying request, same model, no artificial handicap).
- Publish a number without the repo/prompt/model/date it came from — every number here will be reproducible or it won't be here.

## Status

No runs completed yet — v2.0.0 just shipped the workflow engine itself (BLUEPRINT.md Phases 0–6 as of this writing; docs/GitHub-infra/examples still in progress). Benchmark runs are planned for after Phase 10 (release audit), against the `examples/demo-todo-app` golden path once it exists. Check back, or contribute a run — see CONTRIBUTING.md.
