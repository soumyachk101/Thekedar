# A08:2021 — Software and Data Integrity Failures

> OWASP Top 10 (2021), #8 (new in 2021). Code or data is trusted without
> verifying its integrity: unsigned updates, untrusted CI/CD sources, insecure
> deserialization, dependencies pulled from untrusted places.

Cited by: `security-auditor`, `devops-engineer` (CI/CD, supply-chain).

## What it is

The system assumes that code or data it loads is what it expects, without a
cryptographic or provenance check. An attacker who can influence that source
gets to influence execution.

## How it happens (root causes)

- Insecure deserialization: rebuilding objects from attacker-controlled bytes
  (Java/Python `pickle`, PHP `unserialize`, unsafe YAML) → code execution.
- Auto-updates or plugins fetched without signature verification.
- CI/CD pulling actions/images/scripts from mutable or untrusted refs
  (`@main`, `:latest`) with no pinning or checksum.
- Trusting client-provided serialized state (a signed-but-not-verified cookie,
  a hidden field carrying object state).

## Detect (grep + inspection signals)

```
grep -rniE 'pickle\.loads|yaml\.load\(|unserialize|readObject|Marshal\.load'
grep -rniE 'yaml\.load\((?!.*Loader=)' # PyYAML without SafeLoader
# CI pinned by tag/branch, not sha
grep -rnE 'uses:\s*[^@]+@(main|master|v?[0-9]+)$' .github/workflows
grep -rniE ':latest' Dockerfile* docker-compose*
```
Inspect: is any object rebuilt from external bytes? are updates/plugins/CI
sources verified (signature or pinned digest)?

## Exploit scenario

A Python service accepts a base64 blob in a cookie and does `pickle.loads()` on
it to restore session state. An attacker crafts a pickle payload whose
deserialization executes a shell command — full remote code execution, no
memory bug needed. The CI analogue: a workflow uses `some/action@main`; the
action's owner (or an attacker who compromises it) pushes malicious code that
runs with the pipeline's secrets.

## Fix patterns

- Never deserialize untrusted data into live objects. Use data-only formats
  (JSON) with schema validation; if you must, use safe loaders
  (`yaml.safe_load`, allow-listed classes) and integrity-check the payload.
- Sign and verify updates, plugins, and artifacts; verify checksums.
- Pin CI actions and container images by immutable digest (`@sha256:...`),
  not by tag/branch; restrict which secrets each job can read.
- Verify client-provided state with a server-side MAC/signature you check, or
  keep state server-side.

## Verify

- No deserialization of untrusted input into objects in the changed path.
- CI actions/images pinned by digest; least-privilege secrets on jobs.
- Tampered signed payloads/tokens are rejected by a test.

## References

OWASP Top 10 2021 A08 · CWE-502 (deserialization), CWE-345, CWE-494 (unsigned
update), CWE-829.
