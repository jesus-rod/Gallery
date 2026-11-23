# 07 — `-useStubs` launch path

Status: ready-for-agent
Blocked by: 06

`StubHTTPClient` in the app target answers Editorial page N with bundled `editorial-page-N.json` (two pages of 30), and an empty array beyond. The `-useStubs` launch argument selects it in the composition root instead of the authorized client.

## Acceptance
- Unit-tested response mapping (page 1, page 2, page 3 → empty).
- App launched with `-useStubs` shows fixture Photos with no network and no key.
