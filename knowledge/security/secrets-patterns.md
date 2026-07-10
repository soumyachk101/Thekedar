# Secrets — detection patterns and handling rules

> A reference for finding hardcoded secrets in a diff and for the one correct
> way to handle them. Complements the write-time `secret-guard.sh` hook (which
> blocks a subset of these at write time); this pack is for the human/agent
> review that catches the rest.

Cited by: `security-auditor`. Related: OWASP A02 (crypto), A05 (misconfig).

## The rule (there is only one)

Secrets never live in source, config committed to git, logs, URLs, error
messages, or client-side bundles. They live in environment variables or a
secret manager, are read at runtime, and have a placeholder in `.env.example`.
Everything below is about catching violations of that rule.

## High-confidence patterns (a match is almost always a real secret)

```
AKIA[0-9A-Z]{16}                                   # AWS access key id
-----BEGIN [A-Z ]*PRIVATE KEY-----                 # PEM private key
eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+   # JWT
ghp_[A-Za-z0-9]{36}                                # GitHub PAT (classic)
github_pat_[A-Za-z0-9_]{22,}                       # GitHub fine-grained PAT
xox[baprs]-[0-9A-Za-z-]{10,}                       # Slack token
sk_live_[0-9A-Za-z]{16,}                           # Stripe live secret key
sk-ant-[A-Za-z0-9_-]{16,}                          # Anthropic API key
AIza[0-9A-Za-z_-]{35}                              # Google API key
glpat-[0-9A-Za-z_-]{20}                            # GitLab PAT
```

## Contextual patterns (need a look — could be a placeholder)

```
grep -rniE '(api[_-]?key|secret|token|passwd|password|client[_-]?secret)\s*[:=]\s*["'\''][^"'\'' ]{8,}'
grep -rniE '(aws_secret_access_key|db_pass|database_url\s*=\s*[a-z]+://[^:]+:[^@]+@)'
grep -rniE 'authorization:\s*(bearer|basic)\s+[A-Za-z0-9+/=._-]{16,}'
grep -rniE '["'\''][0-9a-f]{32,64}["'\'']'   # long hex literal (key/hash?)
```
Assess each: is the value a real credential, or a placeholder / example / test
fixture? Placeholders (`changeme`, `xxx`, `your-key-here`, `process.env.X`) and
files under `fixtures/`, `*.example`, `*.sample` are fine.

## Detect (where to look)

- The diff itself (`git diff`) — new hardcoded values.
- `.env`, config, compose, CI YAML, Terraform/IaC accidentally committed.
- Client bundles / frontend source (a secret in the browser is public).
- Logs and error handlers that print request headers or config.
- Git history — a secret removed in this commit may still be in history
  (`git log -p -S '<value>'`); removal from HEAD does not rotate it.

## Fix patterns

- Move the value to an env var / secret manager; read at runtime
  (`process.env.X`, `os.environ["X"]`). Add a placeholder line to `.env.example`.
- If a real secret was ever committed: **rotate it** (assume compromised) and
  purge from history if feasible. Redacting the current file is not enough.
- Never log secrets; redact before logging (see A09).
- For sample/test creds, use obvious fakes and put them under an excluded path.

## Verify

- `git diff` shows no literal matching the high-confidence patterns above.
- Any credential is read from env/secret store, with an `.env.example` entry.
- A grep of the built client bundle finds no server secret.
- If a secret was exposed, confirm it was rotated, not just deleted.

## References

OWASP A02/A05 · CWE-798 (hardcoded credentials), CWE-540 (secret in source).
