# 03 — Load more

Status: ready-for-agent
Blocked by: 02

`photoAppeared(_:)` triggers `loadMore` when the Photo is within the last 6 items.

## Acceptance
- An earlier Photo appearing does nothing.
- A Photo within the threshold → footer `loading` → appended Photos, footer `idle` or `end`.
- While a `loadMore` is in flight, further appearances do not call it again.
- Failure → footer `failed(LoadError)`, Photos kept; `retry()` calls the same `loadMore` closure.
- Footer `end` → never calls a loader.
- No retain cycle through the stored `loadMore`.
