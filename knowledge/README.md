# Knowledge packs — the crew's shared brain

Referenced-by-path from agent catalog rows (`catalog/agents.tsv`, column 6) and
validated by `scripts/factory/validate-knowledge.sh`: every pack is ≥ 60
substantive lines and cited by ≥ 1 agent (no orphans, no dangling refs). Agents
consult the matching pack instead of reasoning from memory, and cite the class
(e.g. "A03/CWE-89") in findings.

Each pack follows a **Detect → Exploit → Fix → Verify** shape where applicable:
what the flaw is, grep/inspection signals to find it, a concrete exploit
scenario, fix patterns, and how to confirm the fix.

## security/

**owasp/** — the OWASP Top 10 (2021), one deep file each. Cited by
`security-auditor` (and `a06` also by `dependency-auditor`):

| Pack | Class |
|---|---|
| `owasp/a01-broken-access-control.md` | IDOR, missing authorization, privilege escalation |
| `owasp/a02-cryptographic-failures.md` | weak hashing, missing encryption, key/TLS handling |
| `owasp/a03-injection.md` | SQL / NoSQL / command / XSS |
| `owasp/a04-insecure-design.md` | missing controls by design; abuse cases |
| `owasp/a05-security-misconfiguration.md` | defaults, debug, open CORS/buckets, headers |
| `owasp/a06-vulnerable-components.md` | known-CVE / outdated / unmaintained deps |
| `owasp/a07-auth-failures.md` | brute-force, weak sessions, JWT `alg:none` |
| `owasp/a08-integrity-failures.md` | insecure deserialization, unsigned updates |
| `owasp/a09-logging-monitoring-failures.md` | missing security logs; secrets/PII in logs |
| `owasp/a10-ssrf.md` | server-side request forgery, cloud metadata theft |

Standalone security packs:

| Pack | Topic | Cited by |
|---|---|---|
| `secrets-patterns.md` | hardcoded-secret detection + the one handling rule | security-auditor |
| `authz-checklist.md` | authorization review (IDOR, roles, escalation) | security-auditor |
| `supply-chain.md` | dependency + build/CI supply-chain audit | dependency-auditor, security-auditor |
| `crypto-rules.md` | crypto do/don't: KDFs, AEAD, CSPRNG, constant-time | security-auditor |

## Coming next (MEGA_EXPANSION_1.md §3)

The CWE Top 25; then `best-practices/`, `pitfalls/` (the AI-hallucination-traps
pack — the real differentiator), `review-checklists/`, and `patterns/`. Each
lands as its own validated batch.
