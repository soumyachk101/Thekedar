# Best practices — FastAPI

> Building FastAPI the way its design intends: Pydantic at the edges, dependency
> injection for cross-cutting concerns, async used honestly. Distinct from the
> Python pitfalls pack.

Cited by: `fastapi-specialist`. Related: `pitfalls/python.md`,
`patterns/api-design.md`, `security/authz-checklist.md`.

## Schemas & validation (Pydantic does the work)

- **Separate request and response models** — never return your ORM model
  directly. A `UserCreate` (input), `UserRead` (output), and the DB model are
  three different shapes. This prevents over-exposure and mass-assignment.
- Validate at the boundary with Pydantic v2 types (`EmailStr`, `constr`,
  `Field(gt=0)`); reject bad input with 422 automatically.
- Use `response_model=` so responses are filtered to declared fields — sensitive
  columns can't leak even if the object has them.
- `model_config`/`Field(exclude=...)` to keep internal fields out.

## Dependency injection

- **`Depends()` for everything cross-cutting**: DB sessions, the current user,
  pagination params, settings. Testable (override in tests) and composable.
- Auth as a dependency: `current_user = Depends(get_current_user)`; layer an
  authorization dependency on top that checks the object belongs to the caller
  (`security/authz-checklist.md`).
- Yield-dependencies for setup/teardown (DB session open/close) so resources
  always release.

## Async correctness

- **`async def` endpoints must not block**: use async DB drivers (asyncpg,
  SQLAlchemy async) and `httpx.AsyncClient`. A blocking call in an async route
  stalls the event loop for everyone (`pitfalls/python.md`).
- CPU-bound or unavoidably-blocking work → `run_in_threadpool` / a worker, or make
  the endpoint a plain `def` (FastAPI runs it in a threadpool).
- Reuse clients/pools across requests (app lifespan), don't create per request.

## Structure

- Routers per domain (`APIRouter`), included in the app with a prefix + tags.
- Settings via `pydantic-settings` from env; secrets never hardcoded
  (`security/secrets-patterns.md`).
- Business logic in service functions; endpoints stay thin — parse, authorize,
  call service, shape response.

## API design

- Correct status codes (201 create, 204 no-content, 4xx client, 5xx server);
  consistent error envelope; pagination on list endpoints
  (`patterns/api-design.md`, `patterns/pagination.md`).
- Version the API; document via the auto OpenAPI (add examples, descriptions).
- Idempotency for unsafe retriable operations (`patterns/idempotency.md`).

## Background & lifecycle

- `BackgroundTasks` for fire-and-forget after response; a real queue
  (Celery/arq) for durable/heavy jobs (`patterns/background-jobs.md`).
- `lifespan` context for startup/shutdown (pools, warmup).

## Testing

- `TestClient`/`httpx.AsyncClient` + dependency overrides for DB/auth; test the
  422 validation paths and the authorization paths, not only the happy 200.
