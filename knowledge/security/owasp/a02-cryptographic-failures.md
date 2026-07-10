# A02:2021 — Cryptographic Failures

> OWASP Top 10 (2021), #2 (formerly "Sensitive Data Exposure"). Failures in how
> data is protected in transit and at rest: missing encryption, weak algorithms,
> bad key/password handling — leading to exposure of secrets and personal data.

Cited by: `security-auditor`.

## What it is

The vulnerability is usually not "the crypto math is broken" but "crypto was
missing, misconfigured, or homemade." Focus on: what data is sensitive, is it
encrypted in transit and at rest, and how are keys and passwords handled.

## How it happens (root causes)

- Sensitive data (passwords, tokens, PII, card/health data) sent or stored in
  cleartext.
- Passwords stored with fast/general hashes (MD5, SHA-1, SHA-256) or no salt,
  instead of a password KDF (bcrypt/scrypt/argon2).
- Homemade encryption, ECB mode, static/hardcoded IVs or keys, deprecated
  ciphers (DES, RC4).
- TLS not enforced (mixed content, `http://` endpoints, disabled cert checks).
- Secrets in source, logs, or URLs.

## Detect (grep + inspection signals)

```
grep -rniE 'md5|sha1|des-|rc4|createHash\(|ECB'
grep -rniE 'createCipher\(' # Node: keyless/legacy API, weak; want createCipheriv
grep -rniE 'rejectUnauthorized:\s*false|verify=False|InsecureRequestWarning'
grep -rniE 'password.*=.*(md5|sha256)\(' # fast hash for passwords
grep -rniE 'http://' --include=*.{ts,js,py,go,rb,java} # non-TLS endpoints
```
Inspect: are passwords run through bcrypt/scrypt/argon2? Are keys read from a
secret store/env, not literals? Is TLS verification ever disabled?

## Exploit scenario

An app stores password hashes as unsalted SHA-256. The DB leaks. An attacker
runs a GPU rainbow/brute attack and recovers most passwords in hours because
SHA-256 is fast and unsalted — then credential-stuffs them across other sites.

## Fix patterns

- Passwords: `argon2id` (preferred) or `bcrypt`/`scrypt` with per-user salt and
  a sane cost factor. Never a general-purpose hash.
- Encrypt sensitive data at rest with AES-256-GCM (authenticated) via a random
  per-message IV; keys from a KMS/secret store, rotated.
- Enforce TLS everywhere; never disable certificate verification in production.
- Classify data first — you can't protect what you haven't identified as
  sensitive. Minimize what you store.
- Keep secrets out of code/logs/URLs (see `secrets-patterns.md`, once present).

## Verify

- Confirm the password hash function is a KDF, with salt and cost, in the code path.
- Confirm no cert-verification-disabled flag ships to production.
- Confirm at-rest encryption uses an authenticated mode with a random IV.

## References

OWASP Top 10 2021 A02 · CWE-327 (weak crypto), CWE-916 (weak password hash),
CWE-319 (cleartext transmission).
