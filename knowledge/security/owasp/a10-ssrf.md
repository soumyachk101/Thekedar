# A10:2021 — Server-Side Request Forgery (SSRF)

> OWASP Top 10 (2021), #10 (new in 2021, added by community survey). The server
> is tricked into making a request to an attacker-chosen destination — often an
> internal service or cloud metadata endpoint the attacker can't reach directly.

Cited by: `security-auditor`.

## What it is

Any feature where the server fetches a URL supplied or influenced by the user —
webhooks, link previews, image/PDF fetchers, import-from-URL, SSO metadata — can
be abused to make the *server* request something the *attacker* couldn't.

## How it happens (root causes)

- A user-supplied URL is fetched with no validation of its destination.
- Allowlisting by string prefix that's bypassable (`http://allowed@evil.com`,
  redirects, DNS rebinding, decimal/hex IPs, `[::]`).
- The server sits in a network where internal services and the cloud metadata
  endpoint (`169.254.169.254`) are reachable and unauthenticated.

## Detect (grep + inspection signals)

```
grep -rniE 'fetch\(|axios\.|requests\.(get|post)|http\.get|urllib|HttpClient' 
# ...where the URL comes from input:
grep -rniE '(url|uri|endpoint|webhook|callback|target|dest)\s*[:=].*(req|params|body|query|input)'
grep -rniE 'follow.?redirects?\s*[:=]\s*true'
```
Inspect each outbound request whose URL is user-influenced: is the destination
validated against an allowlist of hosts *after* DNS resolution? are redirects
followed blindly? can it reach internal ranges?

## Exploit scenario

A "add image from URL" feature fetches whatever URL the user gives. The attacker
submits `http://169.254.169.254/latest/meta-data/iam/security-credentials/` —
the server, running on a cloud VM, fetches its own instance credentials and
returns them in the response/preview. The attacker now has cloud keys. Variants
hit internal admin panels, databases, and `localhost`-only services.

## Fix patterns

- Allowlist destinations by host/scheme; validate *after* resolving DNS to an
  IP, and re-check on every redirect (or disable redirect following).
- Block requests to private/link-local/loopback ranges
  (`10/8`, `172.16/12`, `192.168/16`, `127/8`, `169.254/16`, `::1`, `fc00::/7`).
- Fetch from a segmented egress network that cannot reach internal services or
  the metadata endpoint; require IMDSv2 (token-bound) on cloud metadata.
- Don't reflect the raw response back to the user; strip/normalize.
- Prefer a vetted library that has SSRF protections over hand-rolling URL checks.

## Verify

- A request to `169.254.169.254`, `127.0.0.1`, and a private IP is blocked (test).
- A redirect from an allowed host to an internal IP is blocked.
- URL parsing tricks (`user@host`, decimal IP, `[::]`) don't bypass the allowlist.

## References

OWASP Top 10 2021 A10 · CWE-918 (SSRF).
