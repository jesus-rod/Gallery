# 01 — 401 shows an "invalid key" state

Status: done
Blocked by: none

## Files

- Edit: `Gallery/Sources/GalleryCore/UnsplashAPI/UnsplashAPIError.swift`, `EditorialPhotosMapper.swift`, `SearchPhotosMapper.swift` (optionally extract the shared "rate limit, 401, require 200, decode or invalidData" check into one internal helper now that both mappers grow; carried from M1)
- Edit: `Gallery/Tests/GalleryCoreTests/EditorialPhotosMapperTests.swift`, `SearchPhotosMapperTests.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/LoadError.swift`, `StateViews.swift` (title, message, `systemImage: "key"`)
- Edit: `Gallery/Tests/GalleryUITests/GalleryViewModelTests.swift` (the parameterized error-mapping tests gain `.unauthorized → .invalidKey`)
- Edit: `Gallery/Sources/GalleryUI/Localizable.xcstrings`, `Gallery/Sources/GalleryUI/Gallery/GalleryPreviews.swift` (`#Preview("Invalid key")`)
- Edit: `docs/decision-log.md` (new `## M7 — Polish` heading at the end)

## Tests (one at a time)

1. Editorial mapper: 401 throws `.unauthorized`.
2. Search mapper: 401 throws `.unauthorized`.
3. 403 with `X-Ratelimit-Remaining: 0` still throws `.rateLimited` (already covered? keep or add).
4. View model: `load()` failing with `.unauthorized` → `.failed(.invalidKey)`; same for search.

## Strings

Title "Access key not accepted"; message "Check the Unsplash access key in Config/Secrets.xcconfig, then try again."

## Decision log

- A 401 gets its own state ("Access key not accepted"), because a wrong key is the most likely first-run failure for someone setting the project up; the message names the config file.

## Commit

`feat: show an invalid key state when Unsplash rejects the access key`
