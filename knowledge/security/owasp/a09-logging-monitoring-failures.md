# A09:2021 — Security Logging and Monitoring Failures

> OWASP Top 10 (2021), #9. Without sufficient logging, detection, and alerting,
> breaches go unnoticed — the industry average dwell time is measured in weeks.
> Also covers the opposite failure: logging *too much* (secrets/PII in logs).

Cited by: `security-auditor`.

## What it is

Two failure directions: (1) security-relevant events aren't logged/alerted, so
attacks aren't detected or investigable; (2) logs capture sensitive data,
becoming a breach target themselves.

## How it happens (root causes)

- Auth events (login success/failure, lockout, privilege change, access-control
  denials) not logged.
- No alerting/monitoring on anomalies; logs write-only, never watched.
- Logs lack correlation (no request id, no actor, no timestamp/timezone).
- Sensitive data logged: passwords, tokens, full card/PII, secrets, whole
  request bodies.
- Logs mutable/unprotected, or with no retention.
- Errors swallowed silently (`catch {}`) so failures leave no trace.

## Detect (grep + inspection signals)

```
# secrets/PII heading into logs
grep -rniE 'log.*(password|token|secret|authorization|ssn|card)'
grep -rniE 'console\.log\(.*req\.(body|headers)' # whole request logged
# swallowed errors
grep -rnE 'catch\s*\([^)]*\)\s*\{\s*\}|except.*:\s*pass'
# is anything logged around auth at all?
grep -rniE 'login|auth|denied|forbidden' # cross-check for a log call nearby
```
Inspect: are auth and access-control decisions logged with actor + outcome? Is
any secret/PII in a log line? Are errors swallowed?

## Exploit scenario

An attacker brute-forces accounts over two weeks. Because failed logins aren't
logged or alerted, nobody notices until customers report fraud. Investigation is
impossible: there are no records of which accounts were tried or from where.
The inverse: a debug log writes full `Authorization` headers, so anyone with log
access harvests live bearer tokens.

## Fix patterns

- Log security events with enough context to investigate: actor id, source ip,
  action, resource, outcome, and a request/correlation id — with UTC timestamps.
- Alert on anomalies: spikes in auth failures, access-control denials, new-geo
  logins, server errors.
- Redact secrets/PII before logging; never log passwords, tokens, full card/PII,
  or entire request bodies. Log identifiers, not payloads.
- Protect log integrity (append-only/centralized), set retention, and ensure
  logs survive the component that produced them.
- Never swallow errors silently; log with context and re-raise or handle.

## Verify

- A failed login and an access-control denial each produce a log line with actor
  + outcome (test or manual check).
- No secret/PII appears in logs for a request carrying one (grep the output).
- Alerting exists for auth-failure spikes (or is an explicit accepted follow-up).

## References

OWASP Top 10 2021 A09 · CWE-778 (insufficient logging), CWE-532 (sensitive data
in logs), CWE-223.
