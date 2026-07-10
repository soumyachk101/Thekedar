# A01:2021 — Broken Access Control

> OWASP Top 10 (2021), #1. Users act outside their intended permissions:
> reading, modifying, or deleting data they don't own, or reaching admin-only
> functions. The single most common serious web vulnerability class.

Cited by: `security-auditor`. This pack is a checklist and detection guide, not
a substitute for reasoning about the specific app's authorization model.

## What it is

Access control enforces *who can do what*. It breaks when the server trusts a
client-supplied identifier, role, or path without re-checking, on the server,
that the authenticated principal is actually allowed the operation.

## How it happens (root causes)

- Object references (`/api/orders/1043`) served without an ownership check —
  Insecure Direct Object Reference (IDOR).
- Authorization decided in the client/UI (hiding a button) but not the API.
- Role/permission taken from a request field (`?admin=true`, a JWT claim the
  client can set) instead of the server's own record.
- Missing function-level checks: an endpoint exists and is reachable without
  the role its UI implies.
- Path traversal / forced browsing to routes assumed unreachable.

## Detect (grep + inspection signals)

```
# handlers that read an id from the request and fetch by it with no owner scope
grep -rnE '(params|query|body)\.(id|userId|orgId)' --include=*.{ts,js,py,rb,go}
# find-by-id without a tenant/owner clause nearby
grep -rnE 'findByPk|findById|get\(.*id|WHERE id ?=' 
# trust-the-client role checks
grep -rniE 'req\.(body|query|headers)\.(role|isAdmin|admin)'
```
Then read each hit: does the query also constrain by the authenticated user's
id/org? Is there an explicit `can(user, action, resource)` gate before the
mutation? A new endpoint added in this diff with no auth middleware is a hit.

## Exploit scenario

An authenticated user calls `GET /api/invoices/1043`. The handler does
`Invoice.findByPk(req.params.id)` and returns it. User changes `1043` to
`1044` and reads another tenant's invoice. Same pattern on `PATCH`/`DELETE`
lets them modify or destroy other users' records.

## Fix patterns

- Scope every data access by the authenticated principal:
  `Invoice.findOne({ where: { id, orgId: req.user.orgId } })` — not just `id`.
- Deny by default. Centralize checks in middleware/policy objects
  (`can(user, 'read', invoice)`); never rely on the UI hiding an action.
- Derive role/permissions from the server-side session/record, never from a
  client-settable field.
- Use opaque or unguessable ids (UUIDs) as defense-in-depth, not as the control.
- Log access-control failures; rate-limit them.

## Verify

- Write a test: user A cannot read/modify/delete user B's object (expect 403/404).
- Confirm the ownership/tenant clause is in the query, not only in a comment.
- Re-run with the role field stripped/forged — behavior must not change.

## References

OWASP Top 10 2021 A01 · CWE-284, CWE-639 (IDOR), CWE-862 (Missing Authorization).
