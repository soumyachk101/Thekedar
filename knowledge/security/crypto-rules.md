# Cryptography — do / don't rules

> Practical rules for reviewing cryptographic code. The overriding rule: **don't
> invent crypto.** Use vetted, high-level libraries with safe defaults. This
> pack lists the concrete do/don't signals to catch in review.

Cited by: `security-auditor`. Related: OWASP A02 (cryptographic failures).

## The overriding rule

If a change hand-rolls a cipher, a construction, a padding scheme, or a random
generator for a security purpose, that is the finding — regardless of whether
the math looks right. Recommend a vetted library (libsodium/NaCl, the platform's
audited crypto, `cryptography` for Python, Tink) instead.

## Passwords

- **Do**: hash with a password KDF — `argon2id` (preferred), `bcrypt`, or
  `scrypt` — with a per-user salt and a deliberate cost factor.
- **Don't**: use a general/fast hash (MD5, SHA-1, SHA-256, SHA-3) for passwords,
  salted or not. Fast is the enemy here.
- **Don't**: cap password length low or strip characters before hashing.

## Encryption

- **Do**: use authenticated encryption — AES-256-GCM or ChaCha20-Poly1305 — with
  a unique random nonce/IV per message and keys from a KMS/secret store.
- **Don't**: use ECB mode (patterns leak), a static/reused IV, or unauthenticated
  CBC without a separate MAC. Don't reuse a nonce with the same key.
- **Don't**: use DES, 3DES, RC4, or Blowfish for new code.

## Randomness

- **Do**: use a cryptographically secure RNG for tokens/keys/salts/IVs —
  `crypto.randomBytes`, `secrets` (Python), `crypto.getRandomValues` (browser),
  `/dev/urandom`.
- **Don't**: use `Math.random()`, `rand()`, `random.random()`, or a
  time-seeded PRNG for anything security-relevant.

## Hashing & integrity

- **Do**: SHA-256/SHA-3/BLAKE2 for integrity; HMAC (with a secret key) for
  authenticity; constant-time comparison for secrets/MACs/tokens.
- **Don't**: compare secrets with `==`/`===`/`strcmp` (timing side channel);
  use `crypto.timingSafeEqual`/`hmac.compare_digest`.

## Keys & tokens

- **Do**: store keys in a secret manager; rotate; separate keys per purpose.
- **Don't**: hardcode keys, derive keys from low-entropy inputs, or ship the
  same key to every install.
- **JWT**: pin the algorithm, reject `alg: none`, verify with a strong secret/
  key, set short expiry (see A07).

## Detect (grep signals)

```
grep -rniE 'md5|sha1\b|des-|rc4|blowfish|ECB'
grep -rniE 'createCipher\(|Cipher\.getInstance\("AES"\)' # keyless/default-mode
grep -rniE 'Math\.random|random\.random\(|rand\(\)' # near token/key/salt
grep -rniE 'iv\s*=\s*["'\''0]|new byte\[16\]|IV = b?["'\'']' # static IV
grep -rniE '(token|secret|mac|hash)\s*==|strcmp\(' # non-constant-time compare
```

## Verify

- Passwords go through a KDF with salt + cost (read the code path).
- Encryption uses an authenticated mode with a random per-message nonce.
- Tokens/salts/keys come from a CSPRNG; secret comparisons are constant-time.
- No hand-rolled cipher or construction; a vetted library is used.

## References

OWASP A02 · CWE-327 (broken/risky crypto), CWE-338 (weak PRNG), CWE-916 (weak
password hash), CWE-208 (timing side channel).
