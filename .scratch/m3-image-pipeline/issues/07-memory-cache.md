# 07 — Memory-caching image loader

Status: done
Blocked by: 06 (protocol only)

`MemoryCachingImageLoader(decoratee:costLimit:)` over `NSCache`, key = URL + max pixel size, cost = width × height × 4.

## Acceptance
- Second load of the same key → decoratee called once.
- Different max pixel size → separate entry.
- Failure not cached.
- `removeAll()` → next load goes to the decoratee.
- Cost limit configured on the cache (eviction itself is NSCache's; not tested).
