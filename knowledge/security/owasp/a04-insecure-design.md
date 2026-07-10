# A04:2021 — Insecure Design

> OWASP Top 10 (2021), #4 (new in 2021). Flaws in the design itself — missing or
> ineffective control design — as opposed to implementation bugs. You cannot
> patch your way out of an insecure design; it has to be designed in.

Cited by: `security-auditor`, and relevant to `api-designer` when a contract is
being written.

## What it is

The threat wasn't considered at design time, so there's no control to implement
correctly or incorrectly — it's simply absent. Rate limiting, abuse cases,
trust boundaries, and business-logic limits are the usual gaps.

## How it happens (root causes)

- No threat modeling: "what could an attacker do with this flow?" was never asked.
- Missing business-logic limits: unlimited retries, unbounded quantities,
  negative amounts, workflow steps skippable out of order.
- Trusting a step because a *previous* step in the UI enforced it (the API lets
  you jump straight to "confirm").
- No rate limiting / anti-automation on sensitive actions (login, password
  reset, coupon redemption, OTP).
- Recovery flows (password reset, support override) more trusting than login.

## Detect (inspection signals)

Design review, not just grep — but signals:
```
grep -rniE 'rate.?limit|throttle|bucket' # is there ANY? absence on auth is a flag
grep -rniE 'quantity|amount|count|retries|attempts' # bounds checked?
```
Ask of each new flow in the diff: what stops someone doing this a million times?
what stops a negative/huge value? what stops skipping a step? who is trusted and
where is that trust established?

## Exploit scenario

A gift-card redemption endpoint has no rate limit and no per-account cap. An
attacker scripts millions of guesses against short codes and drains balances.
Or: a checkout accepts a client-supplied price/quantity, and a negative
quantity credits the attacker. Neither is an "implementation bug" — the control
was never designed.

## Fix patterns

- Threat-model new features: enumerate abuse cases alongside use cases; write
  them into the task's NOT-in-scope / acceptance criteria.
- Encode business limits server-side: bounds on amounts/quantities, state
  machines that reject out-of-order steps, idempotency keys on money moves.
- Rate-limit and add anti-automation (captcha/proof-of-work/backoff) on
  auth, reset, and any guess-able secret.
- Make recovery flows at least as strong as the primary auth they bypass.
- Reuse vetted design patterns (see `../patterns/` once present) rather than
  inventing a security-relevant flow from scratch.

## Verify

- Each sensitive flow has an explicit limit and a test that hits it.
- Out-of-order / negative / oversized inputs are rejected by a test.
- Rate limiting is present and exercised on auth and reset endpoints.

## References

OWASP Top 10 2021 A04 · CWE-73, CWE-183, CWE-209, CWE-840 (business logic).
