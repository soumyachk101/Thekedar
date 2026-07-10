# A06:2021 — Vulnerable and Outdated Components

> OWASP Top 10 (2021), #6. Running libraries, frameworks, or runtimes with known
> vulnerabilities, or that are unmaintained/outdated. You inherit every CVE in
> your dependency tree, direct and transitive.

Cited by: `security-auditor`, `dependency-auditor` (its whole job).

## What it is

Most application code, by volume, is third-party. A known-vulnerable version of
a popular package is a pre-written exploit anyone can look up. This class is
about *knowing and controlling* what you ship.

## How it happens (root causes)

- Dependencies pinned loosely or not at all; no lockfile committed.
- No audit step; CVEs in the tree are never surfaced.
- Transitive dependencies unmonitored (the vulnerable package is 3 levels deep).
- Unmaintained packages (last release years ago, archived repo).
- Outdated runtime/base image with known kernel/lib CVEs.
- Adding a dependency for a five-line problem, expanding the attack surface.

## Detect (grep + tooling signals)

```
# manifest/lockfile churn is the trigger to audit
git diff --name-only | grep -E 'package(-lock)?\.json|yarn\.lock|pnpm-lock|requirements\.txt|poetry\.lock|go\.(mod|sum)|Gemfile(\.lock)?|Cargo\.(toml|lock)'
# floating / unpinned versions
grep -rnE '"\^|"~|:\s*\*|latest|>=' package.json
```
Then run the ecosystem's audit **if present and fast**:
`npm audit --omit=dev` · `pip-audit` · `cargo audit` · `bundler-audit`. Report
"audit unavailable" honestly rather than inventing results.

## Exploit scenario

An app depends on a logging library version with a known remote-code-execution
CVE (the Log4Shell shape). An attacker sends a crafted string that the library
interprets, and executes code on the server — the app's own code is irrelevant;
the vulnerable component is the door.

## Fix patterns

- Commit lockfiles; pin versions; update deliberately, not via floating ranges.
- Run dependency audit in CI; fail on known-critical CVEs in shipped deps.
- Track transitive deps; prefer packages with active maintenance and few deps.
- Remove unused dependencies; replace trivial one-function packages with code.
- Patch/upgrade the runtime and base images on a schedule, not only on incident.
- For a new dependency: check name (typosquat), maintenance, license, and CVEs
  before adding (see `supply-chain.md`, once present).

## Verify

- Lockfile is committed and consistent with the manifest.
- Audit command runs clean (or the only findings are triaged and documented).
- No unsanctioned new dependency slipped in (the task must allow new deps).

## References

OWASP Top 10 2021 A06 · CWE-1104 (unmaintained), CWE-1035 (known-vuln component).
