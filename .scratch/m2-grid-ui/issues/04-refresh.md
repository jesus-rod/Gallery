# 04 — Pull to refresh

Status: done
Blocked by: 02

`refresh()` reloads the first Page.

## Acceptance
- Success replaces Photos and the stored `loadMore`.
- Failure keeps the current Photos and exposes the mapped error for a brief message.
- A refresh while a `loadMore` is in flight wins: the late `loadMore` result is discarded.
