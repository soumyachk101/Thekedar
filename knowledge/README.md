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
| `feature-flags.md` | deploy vs release, targeting, kill switch, flag-debt cleanup | backend-dev, frontend-dev |
| `background-jobs.md` | enqueue-don't-block, idempotent handlers, retries+DLQ, scheduling | backend-dev, devops-engineer |
| `webhooks.md` | signature verify, idempotency, async ack, SSRF on send | backend-dev, api-designer |
| `file-uploads.md` | size/type validation, server-gen keys, store outside root, scan | backend-dev, frontend-dev |

## review-checklists/

**Per-dimension review lenses** — what a gate checks, as a checklist. Cited by
the read-only review gates:

| Pack | Dimension | Cited by |
|---|---|---|
| `performance.md` | N+1, indexes, hot paths, memory, contention (cost scenarios) | performance-auditor |
| `accessibility.md` | WCAG AA: keyboard, ARIA, names, focus, announcements | accessibility-auditor, frontend-reviewer |
| `error-handling.md` | caught/propagated, right status, safe surfacing, resources | error-checker |
| `logging.md` | no secrets/PII in logs; enough logged; structured; volume | error-checker, security-auditor |
| `testing.md` | behavior + edges, meaningful assertions, isolation, right level | test-writer, error-checker |
| `frontend.md` | state/effects/keys, loading/error/empty, design-system, responsive | frontend-reviewer |

## best-practices/

**Per-framework positive guidance** — what to *do* (architecture, data flow,
security defaults, testing), the complement to `pitfalls/` (what to avoid).
Cited by the matching framework specialist:

| Pack | Framework focus | Cited by |
|---|---|---|
| `react.md` | composition, colocation, effects-minimum, server-vs-client state | react-specialist |
| `nextjs.md` | server-first components, cache layers, Server Actions, `NEXT_PUBLIC` | nextjs-specialist |
| `vue.md` | Composition API, refs vs reactive, composables, Pinia | vue-specialist |
| `angular.md` | standalone + signals, OnPush, RxJS teardown, typed forms, DI | angular-specialist |
| `django.md` | fat-model/thin-view, `select/prefetch_related`, queryset scoping, DRF | django-specialist |
| `fastapi.md` | request/response schema split, `Depends`, async-no-block | fastapi-specialist |
| `express.md` | middleware order, async error adapter, validation, helmet/cors | express-specialist |
| `spring.md` | constructor DI, controller/service/repo, `@Transactional`, DTOs | spring-specialist |
| `rails.md` | convention-first, strong params, N+1 kill, Pundit authz | rails-specialist |
| `laravel.md` | Form Requests, `$fillable` allow-list, Policies, eager-load | laravel-specialist |

## Coming next (MEGA_EXPANSION_1.md §3)

The CWE Top 25 (overlaps OWASP, low priority). The `security/` (14),
`pitfalls/` (8), `patterns/` (12), `review-checklists/` (6), and
`best-practices/` (10) packs are complete — 50 packs total.
