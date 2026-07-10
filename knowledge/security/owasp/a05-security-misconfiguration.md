# A05:2021 — Security Misconfiguration

> OWASP Top 10 (2021), #5. The system is insecure because of how it's
> configured, not how it's coded: default credentials, verbose errors, open
> cloud storage, unnecessary features enabled, missing hardening headers.

Cited by: `security-auditor`, `devops-engineer` (config/infra tasks).

## What it is

Every layer — framework, server, container, cloud, database — ships with
defaults tuned for developer convenience, not production safety. Misconfiguration
is leaving those defaults, or enabling more than the app needs.

## How it happens (root causes)

- Default or example credentials left in place.
- Debug mode / stack traces / detailed errors exposed to users.
- Directory listing, admin consoles, actuator/metrics endpoints publicly reachable.
- Overly permissive CORS (`Access-Control-Allow-Origin: *` with credentials).
- Cloud storage buckets/objects world-readable or world-writable.
- Missing security headers (HSTS, X-Content-Type-Options, frame options, CSP).
- Unpatched/unneeded services and features enabled.

## Detect (grep + inspection signals)

```
grep -rniE 'debug\s*=\s*true|NODE_ENV.*development|app\.debug|FLASK_DEBUG'
grep -rniE 'Access-Control-Allow-Origin.*\*'
grep -rniE 'cors\(\)|origin:\s*true' # reflexive/open CORS
grep -rniE '0\.0\.0\.0|allow all|permitAll|AllowAnyOrigin'
grep -rniE 'password|admin' # in config/compose/env-sample defaults
# infra: public buckets, open security groups
grep -rniE 'public-read|0\.0\.0\.0/0|AllUsers'
```
Inspect config diffs, Dockerfiles, compose files, CI YAML, and cloud IaC.

## Exploit scenario

A Spring Boot app exposes `/actuator/env` publicly; it lists environment
variables including a DB password and an API key. Or an S3 bucket is
`public-read` and an attacker enumerates and downloads customer exports. No
application code was "wrong" — the configuration was.

## Fix patterns

- Change/remove all default credentials; fail startup if a default is detected.
- Disable debug and detailed errors in production; return generic error pages,
  log details server-side only.
- Lock down CORS to an explicit allowlist; never `*` with credentials.
- Add hardening headers (HSTS, `X-Content-Type-Options: nosniff`, frame-ancestors
  via CSP). Restrict admin/metrics endpoints to internal networks + auth.
- Least-privilege cloud: private-by-default storage, tight security groups,
  minimal IAM. Pin and patch base images; remove unused services.
- Keep dev/prod config parity so "works in dev" doesn't hide an unsafe default.

## Verify

- Hit `/actuator`, `/debug`, `/.env`, admin routes as an anonymous user — blocked.
- CORS preflight from a random origin is rejected.
- Security headers present (check response). No secrets in error output.

## References

OWASP Top 10 2021 A05 · CWE-16, CWE-732 (permissions), CWE-548 (dir listing).
