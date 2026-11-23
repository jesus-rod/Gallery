# 01 — Photo gains its Unsplash page URL

Status: done
Blocked by: none

Share (ticket 02) needs the Photo's Unsplash page, `links.html` in the API response.

## Files

- Edit: `Gallery/Sources/GalleryCore/Photos/Photo.swift` (`pageURL: URL`, required, like the profile URL)
- Edit: `Gallery/Sources/GalleryCore/UnsplashAPI/RemotePhoto.swift` (decode top-level `links.html`)
- Edit: `Gallery/Sources/GalleryCore/OfflineFeed/CodableFeedStore.swift` (`LocalPhoto.pageURL`, `Envelope.currentVersion` + 1)
- Edit: `Gallery/Tests/GalleryCoreTests/EditorialPhotosMapperTests.swift`, `SearchPhotosMapperTests.swift`, `CodableFeedStoreTests.swift`, `SharedTestHelpers.swift`
- Edit: every `Photo(...)` call in tests, previews and `Gallery/Tests/GalleryUITests/Helpers/PhotoFixtures.swift`
- Edit: `App/Stubs/Fixtures/editorial-page-*.json`, `search-cats-page-*.json` (add `"links": {"html": …}` to each photo)

## Tests (one at a time)

1. Editorial mapper: maps `links.html` to `pageURL`.
2. Search mapper: same.
3. Editorial mapper: a photo without `links.html` throws `invalidData` (required field, as for the profile URL).
4. Store: round-trips `pageURL`.
5. Store: data saved with the previous version reads as `[]` (already covered by the version test? make sure it still passes with the bump).

## Decision log (new `## M9 — Photos-style polish` heading)

- `Photo` carries its Unsplash page URL, for Share. Sharing the page instead of the image costs no request and isn't a download under Unsplash's guidelines. The offline store version goes up; an old store reads as empty and the network refills it.

## Commit

`feat(core): map each photo's Unsplash page URL`
