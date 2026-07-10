# Best practices — Laravel

> Building Laravel idiomatically: Eloquent used well, the service container and
> framework features leveraged, security defaults intact.

Cited by: `laravel-specialist`. Related: `patterns/migrations.md`,
`security/authz-checklist.md`, `security/owasp/a03-injection.md`.

## Structure & the container

- Thin controllers: validate (Form Requests), authorize (Policies), delegate to
  a service/action class, return a Resource. No business logic in controllers.
- Use the service container + dependency injection (type-hint in constructors/
  methods); bind interfaces to implementations in a service provider for
  swappability.
- Form Request classes for validation + authorization together; keep rules out of
  the controller.

## Eloquent discipline

- **Eager-load to kill N+1**: `Model::with('relation')` for anything you iterate;
  enable `Model::preventLazyLoading()` in dev to catch them.
- Scope queries to the user — `$user->posts()->findOrFail($id)`, never
  `Post::findOrFail($id)` for owned data (IDOR; `security/authz-checklist.md`).
- **`$fillable` allow-list (or guarded) on every model** — never `Model::unguard()`
  or blind `create($request->all())`; mass assignment is the classic Laravel
  vuln. Bind only validated, permitted fields.
- Query scopes for reusable filters; `chunk`/`lazy` for large sets; `exists()`
  over `count() > 0`. Wrap multi-write ops in `DB::transaction()`.

## Migrations

- One change per migration, reversible (`up`/`down`). Index FKs + filtered
  columns. Large-table changes staged to avoid locks (`patterns/migrations.md`).
  Never edit a shipped migration — add a new one.

## Security (defaults on)

- Blade `{{ }}` autoescapes — use `{!! !!}` only for trusted HTML (XSS).
- Eloquent/Query Builder parameterize by default — never `DB::raw` with
  interpolated user input (`security/owasp/a03-injection.md`).
- CSRF middleware stays on for web routes; auth via the framework
  (Sanctum/Fortify/Breeze); passwords bcrypt/argon by default.
- **Authorization via Policies + Gates**, checked in Form Requests or
  controllers; deny by default (`security/authz-checklist.md`).
- Secrets in `.env`, never committed; `config()` reads, not `env()` at runtime
  outside config (`security/secrets-patterns.md`).

## Framework features (use them)

- Queues for mail/notifications/slow work — never in the request
  (`patterns/background-jobs.md`); jobs idempotent + retry-safe.
- Events/listeners to decouple; API Resources to shape JSON (don't return models
  raw — controls exposure); cache for expensive reads
  (`patterns/caching-strategies.md`).
- Task scheduling via the scheduler, not cron-per-command.

## API design

- API Resources for consistent output, correct status codes, pagination
  (`->paginate()`), versioned routes (`patterns/api-design.md`).

## Testing

- Feature tests hit routes with the testing helpers; use factories + `RefreshDatabase`.
  Test validation-failure, authorization (Policy) paths, and mass-assignment
  guards — not just happy paths.
