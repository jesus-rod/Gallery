# 07 — Paging a Stream

Status: ready-for-agent
Blocked by: 01

`Paginated<Item>` (items + optional `loadMore`) and `PhotoStream`, which builds it from a page loader `(Int) async throws -> PhotoPage`. `PhotoStream` owns every stopping rule.

## Acceptance
- First load requests page 1; each `loadMore` requests the next page and returns accumulated Photos.
- Photos with an id already in the Stream are dropped.
- `loadMore` is nil when the page number reaches `totalPages` or a Page comes back empty.
