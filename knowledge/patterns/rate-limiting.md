# Pattern — Rate limiting

> How to bound how often a caller can hit an endpoint — for abuse prevention,
> fair use, and protecting downstream resources.

Cited by: `backend-dev`, `api-designer`. Related: `owasp/a04-insecure-design.md`,
`owasp/a07-auth-failures.md`.

## Problem

Without limits, an endpoint can be brute-forced (login, OTP, coupon), scraped,
or overwhelmed. A04 (insecure design) and A07 (auth failures) both name missing
rate limiting as a root cause. It has to be designed in, not bolted on.

## Approach — algorithms

- **Token bucket**: a bucket refills at a steady rate up to a cap; each request
  spends a token. Allows bursts up to the cap, smooth average. The common default.
- **Fixed window**: N requests per clock window. Simple, but a burst at the
  window boundary allows ~2N. 
- **Sliding window (log/counter)**: smooths the boundary problem; more accurate,
  slightly more state.
- **Leaky bucket**: shapes output to a constant rate.

## Rules

- Key the limit by the right identity: authenticated user/API key for per-account
  limits; IP for anonymous (aware of shared NAT/proxies — trust `X-Forwarded-For`
  only from your own proxy).
- Store counters in a shared store (Redis) so the limit holds across instances —
  an in-memory limiter is per-process and easily bypassed by load balancing.
- Return **429** with a `Retry-After` header; document limits.
- Tighter limits on sensitive actions (login, password reset, OTP, payment) than
  on read endpoints.

## Communicating limits to clients

Rate limiting should be predictable, not a surprise. Return standard headers so
well-behaved clients self-throttle: `RateLimit-Limit`, `RateLimit-Remaining`,
`RateLimit-Reset` (or the `X-RateLimit-*` variants), and on a 429 a `Retry-After`
telling the client when to try again. Document the limits. For your own outbound
calls to a rate-limited third party, honor their `Retry-After` and use
exponential backoff with jitter rather than hammering — a retry storm turns their
throttle into your outage.

## When to use

Every public endpoint, and especially auth, reset, OTP, signup, and anything
guessable or expensive. Also protect downstream/third-party calls with limits +
backoff.

## Pitfalls

- In-memory limiter behind a load balancer → not actually limited.
- Limiting by a spoofable IP header trusted from the internet.
- No limit on the exact endpoints attackers target (auth/reset).
- Blocking legitimate bursts too aggressively — tune the cap; use token bucket.

## Verify

- Exceeding the limit returns 429 + Retry-After (test).
- The limit holds across multiple app instances (shared store).
- Auth/reset endpoints have a limit and a test that trips it.
