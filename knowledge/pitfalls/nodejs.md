# Pitfalls — Node.js

> AI-hallucination traps specific to the Node.js runtime and its ecosystem:
> callback/promise mixing, blocking the event loop, and API-version drift.

Cited by: `backend-dev`, `error-checker`, `devops-engineer`.

## Blocking the event loop

Node is single-threaded for JS. A synchronous or CPU-heavy call blocks *every*
request.

- **Wrong**: `fs.readFileSync` in a request handler · `JSON.parse` on a huge
  payload · a tight CPU loop · `crypto.pbkdf2Sync`/bcrypt-sync in the hot path.
- **Right**: async fs (`fs.promises`), stream large data, offload CPU work to a
  worker thread or a queue, use async crypto.

## Callback / promise / async mixing

- **Wrong**: mixing callback-style (`fn(args, cb)`) and `await` on the same API,
  or wrapping something that's already a promise in `new Promise`.
- **Wrong**: forgetting to `await`, so errors become unhandled rejections and
  the response sends before the work finishes.
- **Right**: pick one style; `util.promisify` legacy callback APIs; always
  `await` (or `.catch`) every promise in a request path.

## Error handling

- An unhandled promise rejection can crash the process (Node 15+). Every async
  route needs a try/catch or an error-handling wrapper.
- Throwing inside an EventEmitter `'error'`-less emitter crashes the process.
- Swallowing errors (`.catch(() => {})`) hides failures — log with context.

## Module system confusion

- CommonJS (`require`, `module.exports`) vs ESM (`import`, `"type": "module"`).
  Mixing them, or using `__dirname`/`require` in ESM (they don't exist there —
  use `import.meta.url`). Mirror the project's `package.json` `type`.
- `node:`-prefixed core imports (`node:fs`) — newer style; be consistent.

## Ecosystem / version drift

- Express 4 vs 5 (error-handling middleware signature, `req.query` parsing).
- `node-fetch` vs the built-in global `fetch` (Node 18+). Don't add `node-fetch`
  if the runtime already has `fetch`.
- Deprecated: `new Buffer()` → `Buffer.from()`/`Buffer.alloc()`. `url.parse` →
  `new URL()`. `crypto.createCipher` → `createCipheriv` (see crypto-rules).
- `process.env` values are strings — `process.env.PORT` is `"3000"`, not `3000`.

## Security-adjacent (see security/ packs)

- Secrets from `process.env`, never hardcoded; validate env at startup.
- `child_process.exec`/`spawn` with `shell:true` and user input = command
  injection; prefer `execFile` with an argv array.
- Path traversal on user-supplied paths joined into `fs` calls.

## Verify

- No `*Sync` fs/crypto call in a request path; no CPU-bound work on the loop.
- Every async route awaits its work and handles errors.
- Module system, `fetch` source, and framework version match the manifest.
