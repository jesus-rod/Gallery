# 03 — Rate limit error

Status: ready-for-agent
Blocked by: 02

Both mappers throw `rateLimited` for a 403 whose `X-Ratelimit-Remaining` header is `0`.

## Acceptance
- 403 without that header stays `invalidData`.
