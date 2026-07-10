# Pattern — File uploads

> How to accept user file uploads safely and scalably: validated, size-bounded,
> stored outside the app, and never trusted as executable or as a safe path.

Cited by: `backend-dev`, `frontend-dev`. Related: `owasp/a03-injection.md`
(path traversal), `owasp/a01-broken-access-control.md`, `patterns/background-jobs.md`.

## Problem

An upload is untrusted bytes plus an untrusted filename plus an untrusted
declared type. Handled naively it becomes: a stored-XSS or malware host, a
path-traversal write, a DoS via huge files, or an access-control leak of other
users' files.

## Approach

- **Bound the size** at the edge (server + proxy limits), not just client-side.
  Unbounded upload = memory exhaustion / disk fill DoS. Reject early.
- **Validate the type by content, not the extension or client `Content-Type`**
  (both are attacker-controlled). Sniff magic bytes; allowlist accepted types.
- **Never trust the filename**: generate your own storage key (UUID); don't use
  the user's filename as a filesystem path (path traversal — `../../etc/...`) or
  reflect it unescaped. Store the original name as metadata only.
- **Store outside the app / web root**: object storage (S3/GCS) or a path not
  served as code. A file served from a code directory can become executable.
- **Serve safely**: `Content-Disposition: attachment` for downloads, correct
  non-executable `Content-Type`, `X-Content-Type-Options: nosniff`; for images,
  re-encode/resize (strips embedded payloads). Never serve user HTML/SVG inline
  from your origin without sanitization (stored XSS).
- **Access control**: scope file access to the owner; use signed, expiring URLs
  for private files rather than guessable public paths (see A01).

## Scale: direct-to-storage + async processing

For large files, have the client upload **directly to object storage** via a
pre-signed URL (the app issues the URL, the bytes never transit your server),
then process (virus scan, thumbnail, transcode) in a **background job** (see
`patterns/background-jobs.md`) rather than blocking the request.

## Malware scanning and quarantine

For files other users will download (attachments, shared documents), scan
uploads for malware before making them available — accept to a quarantine
location, scan asynchronously (a background job), and only then move to the
served location. Serving an unscanned user upload to other users makes you a
malware distribution channel. For internal-only or re-encoded-image uploads the
risk is lower, but never serve an executable type you received verbatim.

## When to use

Any feature accepting user files: avatars, attachments, documents, media,
imports. Treat every one as hostile input.

## Pitfalls

- Trusting the extension/`Content-Type` to decide the file type.
- Using the client filename as a storage path (traversal) or reflecting it (XSS).
- No size limit → DoS. Storing in the web/code root → RCE risk.
- Serving user SVG/HTML inline from your origin (stored XSS).
- Public, guessable file URLs for private content (IDOR — A01).

## Verify

- Oversized upload rejected; type validated by content, not extension.
- Storage key is server-generated; client filename never used as a path.
- Files stored outside the code/web root; private files behind signed URLs.
- Image uploads re-encoded; downloads sent as non-executable attachments.
