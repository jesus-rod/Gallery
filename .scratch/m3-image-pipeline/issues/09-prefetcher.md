# 09 — Image prefetcher

Status: ready-for-agent
Blocked by: 03

`ImagePrefetcher(loader:)`: `prefetch(_ requests: [(URL, maxPixelSize)])` replaces the window.

## Acceptance
- Prefetching starts a load per request.
- A new window cancels loads no longer in it and keeps the ones still in it (no restart).
- Completed loads are dropped from bookkeeping.
- With the dedup layer below, a cancelled prefetch does not cancel a visible cell's load on the same URL (integration test with 03).
