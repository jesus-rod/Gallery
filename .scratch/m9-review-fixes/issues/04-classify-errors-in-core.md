# 04 — Classify load errors in the core, triangulated

Status: ready-for-agent (agree the seam with the user first)
Blocked by: 01

`GalleryUI/Gallery/LoadError.swift` switches over `URLError` codes and `UnsplashAPIError` to pick offline / rate limited / invalid key / generic. The UI module so knows the transport's error types (EF-14). The mapping is also only half tested (EF-32): `GalleryViewModelTests` (around line 29) covers `.notConnectedToInternet`, `.rateLimited` and a generic error; `.networkConnectionLost`, `.dataNotAllowed`, `.timedOut` and `UnsplashAPIError.unauthorized → .invalidKey` are untested.

## Proposed seam (confirm with the user before the first test)

Move the classification into `GalleryCore`, Foundation only:

```swift
public enum LoadFailure: Equatable, Sendable {
    case offline, rateLimited, unauthorized, other
    public init(_ error: any Error)
}
```

- `GalleryUI.LoadError.init(_ error:)` becomes a straight map from `LoadFailure(error)` (`unauthorized → .invalidKey`, `other → .generic`), so no `URLError` or `UnsplashAPIError` appears in `GalleryUI/Gallery/LoadError.swift`.
- Alternative to offer: keep `LoadError` where it is, but have the composition root map errors (decorate the three loader closures). Heavier wiring for the same result; the user picks.
- Naming: check `CONTEXT.md` first and use or add the glossary term.

## Files (for the proposed seam)

- New: `Gallery/Sources/GalleryCore/Errors/LoadFailure.swift`
- New: `Gallery/Tests/GalleryCoreTests/LoadFailureTests.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/LoadError.swift`
- Edit: `docs/decision-log.md`; `CONTEXT.md` if a term is added

## Tests (one at a time, red → green)

Parameterized `@Test(arguments:)` in `LoadFailureTests`:
- each offline code (`.notConnectedToInternet`, `.networkConnectionLost`, `.dataNotAllowed`, `.timedOut`) → `.offline`
- a URLError outside that set (e.g. `.badServerResponse`) → `.other`
- `UnsplashAPIError.rateLimited` → `.rateLimited`; `.unauthorized` → `.unauthorized`; `.invalidData` → `.other`
- an unrelated error → `.other`

Keep the existing `GalleryViewModelTests` cases green; they now cover the UI map end to end.

## Acceptance

- `grep -n "URLError\|UnsplashAPIError" Gallery/Sources/GalleryUI` finds nothing outside previews.
- `swift test` green; lint clean; app builds.

## Decision log

- Load errors are classified in the core (offline / rate limited / unauthorized / other); the UI only maps that classification to its copy, so it no longer knows URLSession error codes. Every offline code and API error is covered by a test.

## Commit

`refactor(core): classify load errors in the core`
