# 02 — `OfflineFeed.saving`: save each loaded Page

Status: done
Blocked by: 01

## Files

- New: `Gallery/Sources/GalleryCore/OfflineFeed/OfflineFeed.swift`
- New: `Gallery/Tests/GalleryCoreTests/OfflineFeedTests.swift`
- New: `Gallery/Tests/GalleryCoreTests/Helpers/FeedStoreSpy.swift` (actor recording `saved: [[Photo]]`, stubbable save error)
- Edit: `docs/decision-log.md`

## Shape

See spec "Shape". Wrap recursively: the returned `Paginated`'s `loadMore` is itself wrapped, so every Page saves.

## Tests (one at a time)

1. A successful first Page saves its items.
2. A failing first Page saves nothing and rethrows the same error.
3. Load more saves all items loaded so far (first Page + second Page).
4. With `limit: 3`, a first Page of 5 saves the first 3.
5. Once a save held `limit` Photos, a later load more saves nothing.
6. A failing save does not fail the load (items and `loadMore` still returned).
7. A failing load more saves nothing new and rethrows.
8. Without more Pages (`loadMore == nil`), the wrapper returns `loadMore == nil`.

## Decision log

- Saving is a decorator around the feed's first-Page closure in Core (`OfflineFeed.saving`): every loaded Page re-saves the first 300 Photos, so the Offline feed is always the latest feed prefix; a save failure never breaks browsing.

## Commit

`feat(core): save each loaded feed Page to the Offline feed`
