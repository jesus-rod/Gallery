# 04 — Unsplash endpoints

Status: ready-for-agent

`UnsplashEndpoint.editorial(page:)` and `.search(query:page:)` build `URLRequest`s against an injected base URL with `per_page=30`.

## Acceptance
- Correct path and query items; query text is percent-encoded.
