# 09 — Image prefetcher

Status: done
Blocked by: 03

`ImagePrefetcher(loader:)`: `prefetch(_ requests: [(URL, maxPixelSize)])` replaces the window.

## Acceptance
- Prefetching starts a load per request.
- A new window cancels loads no longer in it and keeps the ones still in it (no restart).
- Completed loads are dropped from bookkeeping.
- With the dedup layer below, a cancelled prefetch does not cancel a visible cell's load on the same URL (integration test with 03).

## Comments

- `deinit` cancels every prefetch, so a dropped prefetcher never leaves downloads running.
- The ImageLoading copy of the leak trait now polls for up to a second before reporting: a cancelled task can still hold its captures for a few microseconds after the test returns. A real retain cycle is still reported (checked with a throwaway probe).
- `eventually` polls with a 1 ms sleep and a 2 s timeout instead of yielding, since decoding runs on other threads.
