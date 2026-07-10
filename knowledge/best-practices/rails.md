# Best practices — Ruby on Rails

> Building Rails the Rails way: convention over configuration, fat-model/skinny-
> controller, the ORM and security defaults used well. Distinct from `pitfalls/sql.md`.

Cited by: `rails-specialist`. Related: `pitfalls/sql.md`,
`patterns/migrations.md`, `security/authz-checklist.md`.

## Convention over configuration

- Follow Rails naming + structure — pluralized tables, RESTful resources,
  `has_many`/`belongs_to` conventions. Fighting the conventions costs you the
  framework's leverage.
- **Skinny controllers, fat models — but not obese**: business logic on models or
  in POROs / service objects / concerns, not duplicated across controllers.
  Extract a service object when a model grows a god-method.
- RESTful controllers (the seven actions); reach for member/collection routes
  sparingly.

## ActiveRecord discipline

- **Kill N+1 with `includes`/`preload`/`eager_load`** for anything you iterate.
  Add the `bullet` gem in dev to catch them.
- Scope queries to the current user — `current_user.posts.find(params[:id])`,
  never `Post.find(params[:id])` for user-owned data (IDOR;
  `security/authz-checklist.md`).
- Use scopes for reusable query logic; `find_each` for large batches; `pluck`/
  `select` when you don't need full objects; `exists?` over `present?` on a query.
- Validations on the model; DB constraints too (uniqueness races need a unique
  index, not just `validates :uniqueness`).
- Wrap multi-write operations in `transaction`; `with_lock` for read-modify-write.

## Migrations

- Reversible migrations (`change` or explicit `up`/`down`); one concern each.
  Add indexes for FKs and filtered columns. Big-table changes: add column
  nullable → backfill in batches → add constraint, to avoid locking
  (`patterns/migrations.md`). `strong_migrations` gem guards this.

## Security (defaults on)

- **Strong parameters** — `params.require(...).permit(...)` — never
  `permit!`/mass-assign. This is the primary mass-assignment defense.
- CSRF protection stays on; ERB autoescapes — don't `raw`/`html_safe` untrusted
  input (XSS). Parameterize queries; never interpolate params into `where("...")`
  strings (`pitfalls/sql.md`).
- `has_secure_password` (bcrypt) for auth; authorization via Pundit/CanCanCan,
  deny by default.
- Secrets in credentials/env, never committed (`security/secrets-patterns.md`).

## Background jobs

- Offload email, external calls, and slow work to ActiveJob (Sidekiq/GoodJob);
  make jobs idempotent + retry-safe (`patterns/background-jobs.md`). Don't do it
  in the request.

## Performance

- Fragment/Russian-doll caching for expensive views
  (`patterns/caching-strategies.md`); counter caches for counts; database indexes
  for query paths. Paginate (`kaminari`/`pagy`).

## Testing

- RSpec or Minitest; model specs for logic + validations, request specs for
  endpoints, system specs for critical flows. Use factories (`factory_bot`).
  Test authorization + strong-params paths, not only happy CRUD.
