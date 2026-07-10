# Authorization review checklist

> A concrete checklist for auditing whether a change enforces "who can do what"
> correctly. Authorization (authz) is distinct from authentication (authn):
> authn is *who you are*, authz is *what you're allowed to do*. This pack is the
> authz half; see `owasp/a07-auth-failures.md` for authn.

Cited by: `security-auditor`. Related: OWASP A01 (broken access control).

## The core question

For every new or changed endpoint/action/data access: **does the server
re-verify, from its own trusted state, that the authenticated principal is
allowed this exact operation on this exact resource?** If the answer relies on
the client, a request field, or a prior UI step, it's broken.

## Checklist

**Every endpoint / action**
- [ ] Requires authentication (unless deliberately public — and that's stated).
- [ ] Has an explicit authorization check, not just authentication.
- [ ] The check is server-side and centralized (middleware/policy), not ad hoc.
- [ ] Denies by default; access is granted, not un-denied.

**Object / resource access (the IDOR test)**
- [ ] Data reads are scoped by owner/tenant: `WHERE id = ? AND org_id = ?`, not
      just `WHERE id = ?`.
- [ ] Mutations (update/delete) check ownership before acting.
- [ ] A user cannot read/modify/delete another user's object by changing an id.

**Roles / permissions**
- [ ] Role and permissions come from the server's record/session, never a
      client-supplied field (`?admin=true`, a settable JWT claim).
- [ ] Privilege boundaries are enforced on the API, not only hidden in the UI.
- [ ] Vertical (user→admin) and horizontal (user→other user) escalation both
      blocked.

**Sensitive / recovery flows**
- [ ] Admin/support override actions are logged and authorized as strongly as
      the actions they override.
- [ ] Bulk/export/report endpoints are scoped and rate-limited.

## Detect (grep signals)

```
grep -rniE '(findByPk|findById|get\(.*id|WHERE id ?=)' # owner clause nearby?
grep -rniE 'req\.(body|query|headers)\.(role|isAdmin|admin|permissions?)'
grep -rniE '@?(public|permitAll|AllowAnonymous|skipAuth)'
# new routes added in the diff without an auth/authz middleware
git diff | grep -E '^\+.*(router|app)\.(get|post|put|patch|delete)\('
```

## Exploit scenario

`GET /api/reports/:id` returns any report by id with no ownership check. A user
iterates ids and downloads every tenant's report. The fix is one clause:
`Report.findOne({ where: { id, orgId: req.user.orgId } })`.

## Fix patterns

- Centralize authz in a policy layer: `can(user, action, resource)` before every
  sensitive operation; deny by default.
- Scope every query by the authenticated principal's owner/tenant id.
- Derive roles server-side; treat all client-supplied authz hints as untrusted.
- Add tests that assert cross-user and cross-role access is refused.

## Verify

- Test: user A → user B's object returns 403/404 on read, update, delete.
- Test: a forged/stripped role field does not change what's permitted.
- Every new endpoint in the diff has a demonstrable authz gate.

## References

OWASP A01 · CWE-862 (missing authorization), CWE-863 (incorrect authorization),
CWE-639 (IDOR).
