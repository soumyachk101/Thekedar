# Best practices — Spring Boot

> Building Spring Boot the idiomatic way: constructor injection, clear layering,
> transactions and security configured correctly.

Cited by: `spring-specialist`. Related: `patterns/api-design.md`,
`patterns/error-handling.md`, `security/authz-checklist.md`.

## Dependency injection

- **Constructor injection, always** — `final` fields set via the constructor.
  Makes dependencies explicit, supports immutability, and is trivially testable
  without the container. Avoid field `@Autowired` (hidden deps, hard to test).
- Program to interfaces where you need swappability; let Spring wire impls.
- Prefer `@Component`/`@Service`/`@Repository` stereotypes over generic beans so
  intent + component-scanning are clear.

## Layering

- **Controller → Service → Repository**. Controllers do HTTP (parse, validate,
  map, status); services own business logic + transactions; repositories own
  persistence. No business logic in controllers, no HTTP concerns in services.
- **DTOs at the boundary** — never expose JPA entities in the API. Map
  entity↔DTO (MapStruct or explicit). This prevents lazy-loading serialization
  blowups and over-exposure.

## Transactions & JPA

- `@Transactional` at the service layer, not the repository or controller. Know
  the boundary — a transaction spans the whole business operation.
- **Beware N+1**: use fetch joins / `@EntityGraph` for what you iterate; keep
  associations `LAZY` by default and fetch deliberately.
- Don't leak the persistence context: no lazy access outside the transaction
  (map to DTO inside it). Use pagination (`Pageable`) for lists.
- Validate with Bean Validation (`@Valid` + constraints) at the controller.

## Configuration

- `application.yml` per profile; secrets from env / a vault, never committed
  (`security/secrets-patterns.md`). `@ConfigurationProperties` (typed) over
  scattered `@Value`.
- Actuator for health/metrics; expose only what's needed, secured.

## Error handling

- `@RestControllerAdvice` + `@ExceptionHandler` for a centralized, consistent
  error response (status + body). Map domain exceptions to HTTP; don't leak stack
  traces (`patterns/error-handling.md`).
- Use `ResponseStatusException` or typed exceptions, not raw 500s.

## Security (Spring Security)

- Method- or request-level authorization; deny by default. Check the resource
  belongs to the principal (IDOR; `security/authz-checklist.md`).
- Passwords via `PasswordEncoder` (bcrypt/argon2); stateless JWT or server
  sessions configured deliberately; CSRF on for browser/session apps.
- Validate + bind request bodies to DTOs with explicit fields (no mass
  assignment onto entities).

## API design & performance

- REST conventions, correct status codes, pagination, versioning
  (`patterns/api-design.md`). Cache read-heavy endpoints (`@Cacheable`).
- Async/`@Async` or a queue for slow work (`patterns/background-jobs.md`);
  set timeouts on `RestClient`/`WebClient` calls.

## Testing

- `@WebMvcTest` (slice) for controllers with `MockMvc`; `@DataJpaTest` for
  repositories; `@SpringBootTest` sparingly for full-context integration.
  Testcontainers for a real DB. Test the security + transaction boundaries.
