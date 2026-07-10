# Best practices — Django

> Building Django/DRF the way the framework rewards: fat models / thin views,
> the ORM used well, security defaults left on. Distinct from `pitfalls/python.md`.

Cited by: `django-specialist`. Related: `pitfalls/python.md`,
`patterns/migrations.md`, `security/authz-checklist.md`.

## Project structure

- **Apps are bounded contexts**, not layers. One app per cohesive domain; keep
  them small and reusable. Don't make a monolithic `core` app that owns everything.
- **Settings per environment** via a base + overrides (or `django-environ`);
  secrets from env, never in `settings.py` (`security/secrets-patterns.md`).
  `DEBUG = False` in prod, `ALLOWED_HOSTS` set, `SECRET_KEY` from env.
- Fat models / service functions, thin views. Business logic belongs on the model
  or in a service module, not copy-pasted across views.

## ORM discipline

- **Kill N+1**: `select_related` (FK/one-to-one, JOIN) and `prefetch_related`
  (M2M/reverse FK, second query) for anything you loop over. This is the single
  biggest Django performance win.
- `only()`/`defer()`/`values()` when you don't need whole objects; `.exists()`
  instead of `len(qs)`; `.count()` instead of `len(list(qs))`.
- **Scope querysets to the request user** — `Model.objects.filter(owner=request.user)`
  — never trust a client-supplied id without an ownership check (IDOR;
  `security/authz-checklist.md`).
- Use `F()`/`Q()` expressions and `update()` for atomic, race-free writes;
  `select_for_update()` inside a transaction for read-modify-write.
- Wrap multi-write operations in `transaction.atomic()`.

## Migrations

- One logical change per migration; review the generated SQL. Data migrations
  separate from schema; provide a reverse where feasible. Big-table changes go
  expand → migrate → contract to avoid downtime (`patterns/migrations.md`).

## Views & DRF

- Class-based / generic views to reuse behavior; keep them declarative.
- **DRF serializers validate + shape** — never bind request data straight to a
  model. Set read-only fields; don't expose internal fields; authorize per object
  (`permission_classes`, `get_queryset` scoping).
- Paginate list endpoints; filter/order via `django-filter`, not hand-rolled query
  parsing.

## Security (defaults are your friend)

- Leave CSRF, XSS-escaping, and clickjacking middleware on. Template autoescaping
  stays on — don't `|safe` untrusted data.
- Auth via the built-in system; passwords hashed by Django's KDF; permissions +
  groups for authorization. HTTPS/secure-cookie/HSTS settings in prod.
- Validate + sanitize file uploads; store media outside the app root.

## Async & tasks

- Offload slow/external work to Celery/RQ, not the request cycle
  (`patterns/background-jobs.md`); make tasks idempotent and retry-safe.

## Testing

- `pytest-django` or `TestCase`; use factories (`factory_boy`) over fixtures;
  test permissions + querysets (the security-relevant paths), not just happy CRUD.
- `assertNumQueries` to lock down N+1 regressions.
