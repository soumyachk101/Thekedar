# Supply-chain security — dependencies and the build

> Auditing what you pull in and how you build it. A dependency you add runs with
> your app's privileges; a compromised build step runs with your pipeline's
> secrets. This pack drives the dependency-manifest review.

Cited by: `dependency-auditor` (its core), `security-auditor`. Related: OWASP
A06 (vulnerable components), A08 (integrity failures).

## Threat model

Three ways a dependency or build hurts you: (1) it has a **known vulnerability**
(A06); (2) it is **malicious** — typosquat, hijacked maintainer account, or a
poisoned version; (3) the **build/CI** pulls untrusted code or leaks secrets
(A08). This pack covers 2 and the review side of 1 and 3.

## When to audit

Any diff that touches a manifest or lockfile:
```
git diff --name-only | grep -E 'package(-lock)?\.json|yarn\.lock|pnpm-lock\.yaml|requirements\.txt|poetry\.lock|Pipfile\.lock|go\.(mod|sum)|Gemfile(\.lock)?|Cargo\.(toml|lock)|composer\.(json|lock)'
```

## Checklist for each ADDED or major-bumped dependency

- [ ] **Sanctioned** — the task explicitly allows a new dependency. An
      unsanctioned new dep is an automatic finding (the doer broke the rule).
- [ ] **Name is legit** — not a typosquat of a popular package (`lodahs`,
      `reqests`, `python-dateutil` vs `dateutil`), not a brand-new name for a
      long-solved problem, not a suspicious scope.
- [ ] **Maintained** — recent releases, not archived, reasonable download count,
      a real repository.
- [ ] **Pinned** — exact version or a committed lockfile; no floating `*`/
      `latest`/unbounded `>=`.
- [ ] **License compatible** — copyleft (GPL/AGPL) entering a permissive/
      proprietary codebase is a human-decision flag.
- [ ] **No unexpected install scripts** — postinstall/preinstall hooks are a
      known malware vector; note them.
- [ ] **Necessary** — a one-function package (left-pad-shaped) that five lines
      of code replace expands the attack surface for little gain.

## Build / CI checklist

- [ ] CI actions and container images pinned by immutable digest
      (`@sha256:...`), not a mutable tag/branch (`@main`, `:latest`).
- [ ] Jobs get least-privilege secrets; untrusted PR code can't read prod secrets.
- [ ] Lockfile is committed and consistent with the manifest.
- [ ] An audit step runs (`npm audit`, `pip-audit`, `cargo audit`, ...).

## Detect / tooling

```
grep -rnE '"\^|"~|:\s*\*|latest|>=' package.json    # floating versions
grep -rniE '"(pre|post)install"\s*:' package.json    # install hooks
grep -rnE 'uses:\s*[^@]+@(main|master|v?[0-9.]+)$' .github/workflows  # unpinned CI
```
Run the ecosystem audit if present and fast; report "audit unavailable" rather
than inventing results. Never install/execute the dependency to inspect it.

## Fix patterns

- Pin everything; commit lockfiles; update deliberately.
- Reject unsanctioned deps back to the doer; require the task to allow new deps.
- Replace trivial packages with code; remove unused ones.
- Pin CI by digest; scope secrets per job; add an audit gate to CI.

## Verify

- No unsanctioned or floating dependency in the diff.
- Audit runs clean (or findings are triaged and documented).
- CI actions/images are digest-pinned; lockfile committed and consistent.

## References

OWASP A06/A08 · CWE-1104, CWE-829 (untrusted functionality), CWE-494.
