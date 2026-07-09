# ADR 0005 — Model routing: Sonnet workhorses, Haiku for pattern-matching, inherit for judgment

**Date:** 2026-07-09 · **Status:** accepted

## Context

15 agents, each invoked at least once per relevant task, is where multi-agent orchestration's token cost either stays reasonable (2–4×, the stated target) or balloons. Model choice per agent is the main lever, and different agents genuinely need different capability levels — a dependency-manifest diff check is not the same reasoning task as designing an API contract.

## Decision

Three tiers, assigned per agent by what the role actually demands: **inherit** (planner, api-designer — planning quality and contract correctness compound into everything downstream, worth the user's chosen top-tier model); **sonnet** (every implementation doer and every reasoning-heavy gate — backend-dev, frontend-dev, test-writer, db-specialist, devops-engineer, refactor-specialist, error-checker, security-auditor, frontend-reviewer, performance-auditor, accessibility-auditor — the workhorse tier, cost-efficient at the volume these fire); **haiku** (docs-writer, dependency-auditor — genuinely lighter reasoning: summarizing known facts into prose, and pattern-matching a manifest diff against known-bad signatures).

## Consequences

Easier: cost stays roughly proportional to the number of *tasks*, not agents-times-tasks, because most invocations are the cheaper tiers; the two `inherit` agents concentrate the expensive-model spend where a bad call is costliest (a bad plan or a bad API contract propagates to every downstream task). Harder: the tiering is a judgment call, not a formula — a project with unusually complex dependency trees might find dependency-auditor's Haiku tier under-powered, and the fix is a one-line frontmatter edit per TRD §3.3, not a system redesign.

## Alternatives considered

- **Everything on the user's top-tier model** — rejected: directly contradicts the 2–4× cost target; most gate/doer work doesn't need frontier reasoning to execute a well-specified task correctly.
- **Everything on the cheapest available model** — rejected: planning and API-contract mistakes are expensive to unwind later (every downstream task inherits them) — this is the one place worth spending on quality up front.
