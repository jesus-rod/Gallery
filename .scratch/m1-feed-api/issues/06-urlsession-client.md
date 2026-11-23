# 06 — URLSession HTTP client

Status: done

`URLSessionHTTPClient` implements `HTTPClient` over an injected `URLSession`.

## Acceptance
- Sends the given request; delivers data + HTTPURLResponse; throws on transport error and on a non-HTTP response. Tested with a URLProtocol stub.
