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

## pitfalls/

**AI-hallucination traps** — the differentiator. What models write that is
*plausible and wrong*: invented APIs, hallucinated imports, deprecated patterns
still emitted, version confusions. Doers read them to avoid the traps;
`error-checker` reads `general-ai-coding.md` to catch them.

| Pack | Traps | Cited by |
|---|---|---|
| `general-ai-coding.md` | invented APIs, hallucinated packages, version drift, deprecated patterns, confident-wrong config | backend-dev, frontend-dev, error-checker |
| `python.md` | Python-2-isms, mutable defaults, async, `is` vs `==` | backend-dev |
| `typescript-javascript.md` | invented Array/String methods, `as any`, async, ESM/CJS | backend-dev, frontend-dev |
| `react.md` | deprecated lifecycle, hook rules, effect deps, state mutation | frontend-dev |
| `nodejs.md` | event-loop blocking, callback/promise mixing, version drift | backend-dev |
| `sql.md` | injection by concat, migration hazards, N+1, dialect drift | db-specialist, backend-dev |
| `go.md` | ignored errors, loop capture, goroutine leaks, append aliasing | backend-dev |
| `api-http.md` | wrong status codes, shape drift, idempotency, breaking changes | api-designer, backend-dev |

## patterns/

**Reusable design patterns** — Problem → Approach → When → Pitfalls → Verify.
Cited by the doers and `api-designer`/`performance-auditor`/`devops-engineer`:

| Pack | Topic | Cited by |
|---|---|---|
| `api-design.md` | resources, one error envelope, versioning, bulk/fields | api-designer, backend-dev |
| `error-handling.md` | loud-internal/generic-external, wrapping, retries, breakers | backend-dev, error-checker |
| `migrations.md` | reversible, expand/contract, batched backfill, zero-downtime | db-specialist, backend-dev |
| `pagination.md` | offset vs cursor, max page size, stable order, count cost | backend-dev, api-designer |
| `idempotency.md` | idempotency keys, natural idempotency, dedup, retry safety | backend-dev, api-designer |
| `rate-limiting.md` | token bucket, shared store, 429+Retry-After, backoff | backend-dev, api-designer |
| `caching-strategies.md` | cache-aside, invalidation, TTL, per-principal keys | backend-dev, performance-auditor |
| `observability.md` | structured logs, metrics (RED), traces, correlation id, SLOs | backend-dev, devops-engineer |

## Coming next (MEGA_EXPANSION_1.md §3)

The CWE Top 25; `best-practices/` (per-framework conventions); `review-checklists/`
(per-dimension: perf, a11y, error-handling, logging, testing); and the remaining
`patterns/` (feature-flags, background-jobs, webhooks, file-uploads). Each lands
as its own validated batch.
