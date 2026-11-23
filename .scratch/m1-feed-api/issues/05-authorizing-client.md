# 05 — Authorizing HTTP client

Status: done

`AuthorizingHTTPClient` decorates `HTTPClient`, adding `Authorization: Client-ID <key>` and `Accept-Version: v1`.

## Acceptance
- Forwards the response and errors unchanged; keeps the original request's URL and other headers.
