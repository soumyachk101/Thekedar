# Pattern — Feature flags

> How to ship code decoupled from releasing behavior: turn features on/off at
> runtime, roll out gradually, and kill a bad change without a redeploy.

Cited by: `backend-dev`, `frontend-dev`. Related: `patterns/migrations.md`
(coordinating schema + behavior changes).

## Problem

Merging a half-done feature blocks everyone; releasing a risky feature to 100%
of users at once is dangerous; a bad deploy needs a fast rollback that doesn't
require a full redeploy. Feature flags separate *deploy* (code is present) from
*release* (behavior is on).

## Approach

- **A flag is a runtime condition**: `if (flags.isEnabled("new-checkout", ctx))`.
  Evaluated per request/user, not baked in at build.
- **Flag types**: release toggles (ship-dark, flip on later), experiment toggles
  (A/B), ops toggles (kill switch for load), permission toggles (entitlements).
  Know which kind you're building — they have different lifetimes.
- **Targeting**: enable for a % of users, a specific cohort, internal staff
  first, then widen. Use a stable hash of the user id so a user's assignment is
  consistent across requests.
- **Default off / safe**: an unknown or errored flag evaluates to the safe
  (usually old) behavior. Flag lookups must never break the request.
- **Kill switch**: every risky feature ships behind a flag you can flip off
  instantly without a deploy — the fastest rollback there is.

## Lifecycle discipline

Flags are debt. A release toggle should be **removed** once the feature is fully
rolled out and stable — a codebase full of stale flags with dead branches is a
maintenance and testing nightmare (2^n code paths). Track flags; schedule their
removal; delete both the flag and the dead branch.

## Where to evaluate — server vs client

Evaluate authorization- or security-relevant flags on the **server** and send
only the decision (or the already-gated data) to the client — a client-side flag
is visible and flippable by the user, so it must never be the only thing
protecting a paid or privileged feature. Pure-presentation flags (which banner,
which layout) can be evaluated client-side. For SSR/edge, evaluate before render
so the user doesn't see a flicker of the wrong variant.

## When to use

Trunk-based development (merge incomplete work safely), gradual/canary rollouts,
A/B experiments, and any change risky enough to want an instant off switch.

## Pitfalls

- Flags that never get cleaned up → combinatorial dead code and test paths.
- Flag evaluation that can throw/block and take down the request path.
- Inconsistent assignment (a user flips between variants across requests).
- Testing only one flag state; both branches need coverage.
- Putting entitlements/authz solely in a client-side flag (bypassable — enforce
  server-side, see `owasp/a01-broken-access-control.md`).

## Verify

- Flag defaults to the safe behavior on error/unknown; lookup can't break a request.
- User assignment is stable (same user → same variant).
- Both on and off branches are tested.
- Stale flags have a removal owner/date.
