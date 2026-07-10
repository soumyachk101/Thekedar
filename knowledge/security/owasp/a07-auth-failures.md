# A07:2021 — Identification and Authentication Failures

> OWASP Top 10 (2021), #7 (formerly "Broken Authentication"). Weaknesses in
> proving who a user is: guessable credentials, broken session handling, missing
> brute-force protection, weak recovery flows.

Cited by: `security-auditor`.

## What it is

Authentication answers "who are you?" It fails when identity can be guessed,
stolen, replayed, or bypassed — letting an attacker become another user.

## How it happens (root causes)

- No brute-force / credential-stuffing protection (unlimited login attempts).
- Weak password policy; no check against known-breached password lists.
- Session tokens that don't rotate on login, don't expire, or are guessable.
- Tokens/session ids in URLs, or not invalidated on logout/password change.
- Missing or bypassable multi-factor authentication.
- Password reset flows that leak account existence or use guessable tokens.
- JWTs accepted with `alg: none`, or verified with a weak/shared secret.

## Detect (grep + inspection signals)

```
grep -rniE 'jwt|jsonwebtoken|verify\(' # check alg pinning + secret source
grep -rniE 'alg.*none|algorithms?\s*:\s*\[' # 'none' or over-broad alg list
grep -rniE 'session|cookie' # httpOnly? secure? sameSite? rotation on login?
grep -rniE 'login|signin|authenticate' # any rate limit / lockout near it?
grep -rniE 'reset.?token|forgot' # token entropy + expiry + single-use?
```
Inspect: does login rotate the session id? do cookies set HttpOnly+Secure+
SameSite? is there a lockout/backoff? does JWT verification pin the algorithm
and read the secret from a secret store?

## Exploit scenario

A login endpoint has no rate limit. An attacker takes a leaked
username/password list from another breach and credential-stuffs it; a few
percent succeed because users reuse passwords. Or: the API verifies JWTs with a
library call that accepts `alg: none`, so an attacker forges a token with any
user id and no signature.

## Fix patterns

- Rate-limit and lock out / back off on repeated failures; add MFA for
  sensitive accounts and actions.
- Enforce strong passwords; screen against breached-password lists; store with
  a KDF (see A02).
- Sessions: rotate the id on login and privilege change; short idle + absolute
  timeouts; invalidate on logout and password change. Cookies HttpOnly, Secure,
  SameSite=Lax/Strict; never put session ids in URLs.
- JWTs: pin the expected algorithm, reject `none`, verify with a strong secret/
  key from a secret store, set short expiry, and check `exp`/`aud`/`iss`.
- Password reset: high-entropy, single-use, short-lived tokens; identical
  response whether or not the account exists (no enumeration).

## Verify

- A test confirms N failed logins triggers lockout/backoff.
- A forged `alg: none` / wrong-signature token is rejected.
- Logout and password change invalidate existing sessions (test).
- Reset for a nonexistent account returns the same response as a real one.

## References

OWASP Top 10 2021 A07 · CWE-287, CWE-384 (session fixation), CWE-307 (no
brute-force protection), CWE-345.
