# 02 — Load the first Page

Status: ready-for-agent
Blocked by: 01

`GalleryViewModel` with `feed: StreamState`, built from `loadFeed: () async throws -> Paginated<Photo>`. `load()` moves `loading` → `loaded(photos, footer)` or `failed(LoadError)`.

## Acceptance
- Starts in `loading`; `load()` calls the loader once.
- Success → `loaded` with the Photos; footer `idle` when `loadMore` exists, `end` when nil.
- Errors map: `UnsplashAPIError.rateLimited` → `rateLimited`; `URLError` `.notConnectedToInternet`, `.networkConnectionLost`, `.dataNotAllowed`, `.timedOut` → `offline`; anything else → `generic`.
- `retry()` from `failed` calls the loader again.
- Every test asserts the view model is deallocated.
