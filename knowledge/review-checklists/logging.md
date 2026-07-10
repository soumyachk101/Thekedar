# Review checklist — logging

> What to check about logging in a diff — both directions: enough logged to
> operate and investigate, and nothing sensitive leaked into the logs.

Cited by: `error-checker`, `security-auditor`. Related: `owasp/a09-logging-
monitoring-failures.md`, `patterns/observability.md`.

## Nothing sensitive in logs (the security direction)

- [ ] No secrets logged: passwords, tokens, API keys, `Authorization` headers,
      connection strings, private keys.
- [ ] No PII logged where it shouldn't be: full card numbers, SSNs, health data,
      raw personal data — log identifiers, not payloads.
- [ ] Whole request/response bodies not dumped (they carry secrets/PII).
- [ ] Redaction applied before logging structured objects that may contain the above.

## Enough logged (the operations direction)

- [ ] Security-relevant events logged: auth success/failure, lockout, privilege
      change, access-control denial — with actor + outcome (see A09).
- [ ] Errors logged with enough context to investigate (see error-handling
      checklist) — not swallowed silently.
- [ ] A correlation / request id is present so one request's logs are linkable
      (see `patterns/observability.md`).

## Quality & consistency

- [ ] **Structured** logging (key-value/JSON), not free-text string concatenation
      that can't be queried — matches the project's existing logger.
- [ ] Appropriate **level**: error for failures, warn for recoverable oddities,
      info for milestones, debug for detail — not everything at `error`, not
      secrets at `debug`.
- [ ] Not so noisy it's useless or expensive (logging inside a tight loop, logging
      the same thing at every layer).
- [ ] Timestamps in UTC; consistent format.

## Uses the project's logger

- [ ] Uses the existing logging library/util, not a stray `console.log` / `print`
      / `System.out` left in (those bypass levels, formatting, and redaction).

## Volume, cost, and retention

- [ ] High-traffic paths don't log a line per request at `info` in a way that
      floods storage and cost — sample or aggregate hot events.
- [ ] Debug logging isn't left enabled in production (it's verbose and can leak
      detail); it's gated by level/config.
- [ ] No logging inside a tight loop that turns one operation into thousands of
      lines.
- [ ] Sensitive-but-necessary audit logs have a defined retention and are
      protected (append-only / centralized), not left in a world-readable file.

## Correlation across services

- [ ] The correlation/request id is **propagated** to downstream calls and
      included in their logs, so one logical request is reconstructable end-to-end
      across service boundaries — not just within one process.

## Verify

- Grep the diff: no `console.log`/`print` of `password|token|secret|authorization`
  or whole request bodies.
- A failed auth and an access denial each produce a log line with actor + outcome.
- Logs are structured and use the project logger, not ad-hoc prints.
