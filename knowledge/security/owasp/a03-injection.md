# A03:2021 — Injection

> OWASP Top 10 (2021), #3. Untrusted input is interpreted as code or a command:
> SQL, NoSQL, OS command, LDAP, and cross-site scripting (XSS) all live here.
> The classic "the data became instructions" bug.

Cited by: `security-auditor`.

## What it is

Any place a string built partly from user input is handed to an interpreter —
a SQL engine, a shell, a template, the browser DOM — without the input being
kept strictly as *data*.

## How it happens (root causes)

- SQL built by concatenation/format: `"... WHERE name='" + name + "'"`.
- Shell commands built from input: `exec("convert " + userFile)`.
- Rendering user HTML via `innerHTML`/`dangerouslySetInnerHTML`/unescaped
  templates (→ XSS).
- NoSQL query objects taken from request bodies (`{ $where: req.body.q }`).
- ORMs used in a raw-string escape hatch that reintroduces concatenation.

## Detect (grep + inspection signals)

```
# SQL string building
grep -rnE "(SELECT|INSERT|UPDATE|DELETE).*(\+|\$\{|%s|format\()"
grep -rniE 'execute\(|raw\(|query\(' # check args for concatenation
# command execution from input
grep -rniE 'exec\(|execSync|os\.system|subprocess.*shell=True|Runtime\.exec'
# XSS sinks
grep -rniE 'innerHTML|dangerouslySetInnerHTML|v-html|\|\s*safe|render_template_string'
# NoSQL operator injection
grep -rniE '\$where|\$regex' 
```
Inspect each: is the variable part a bound parameter, or spliced into the string?

## Exploit scenario

Login does `db.query("SELECT * FROM users WHERE email='" + email + "'")`.
Attacker submits `' OR '1'='1' --` as email → query returns the first user and
authenticates them. A `; DROP TABLE users; --` variant destroys data. The XSS
analogue: a comment field rendered with `innerHTML` runs attacker `<script>`
in every viewer's session.

## Fix patterns

- **Parameterized queries / prepared statements, always.** Bind values; never
  concatenate. Use the ORM's parameter binding, not its raw-string escape hatch.
- Shell: avoid `shell=True`; pass argv arrays (`execFile(cmd, [args])`); prefer
  a library API over shelling out. If unavoidable, allowlist inputs.
- XSS: render as text by default; escape on output; use a strict template
  engine and a Content-Security-Policy. Sanitize any intentional HTML with a
  vetted sanitizer (DOMPurify), never a regex.
- Validate/allowlist at the trust boundary as defense-in-depth (type, length,
  format) — but validation is not a substitute for parameterization.

## Verify

- Grep the diff shows zero string-built queries/commands in the changed path.
- A test with a metacharacter payload (`'`, `;`, `<script>`) is treated as data.
- CSP header present for HTML responses.

## References

OWASP Top 10 2021 A03 · CWE-89 (SQL), CWE-78 (OS command), CWE-79 (XSS),
CWE-943 (NoSQL).
