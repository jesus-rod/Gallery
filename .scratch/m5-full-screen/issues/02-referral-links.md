# 02 — Unsplash referral links

Status: done
Blocked by: none

Core only. Unsplash's API guidelines ask every link back to a Photographer's profile or to Unsplash to carry `utm_source=<app name>&utm_medium=referral`. A caseless enum builds those URLs; the app name is a parameter, so the UI module hard-codes nothing (the composition root passes `gallery_ios` in ticket 05).

## Files

- New: `Gallery/Sources/GalleryCore/UnsplashAPI/UnsplashAttribution.swift`
- New: `Gallery/Tests/GalleryCoreTests/UnsplashAttributionTests.swift`
- Edit: `docs/decision-log.md`

## Shape

```swift
public enum UnsplashAttribution {
    public static func referralURL(_ url: URL, appName: String) -> URL
    public static func unsplashURL(appName: String) -> URL      // https://unsplash.com/ with the referral items
}
```

Same approach as `sizedURL`: `URLComponents`, drop any existing `utm_source` / `utm_medium`, append the two new items, fall back to the input URL if components cannot be built.

## Tests (one at a time, red → green)

- `referralURL_addsTheAppNameAsSourceAndReferralAsMedium`: `https://unsplash.com/@jane` + `gallery_ios` → query items exactly `utm_source=gallery_ios`, `utm_medium=referral`; scheme, host and path unchanged.
- `referralURL_keepsExistingQueryItems`: `https://unsplash.com/@jane?lang=en` keeps `lang=en`.
- `referralURL_replacesExistingReferralItemsInsteadOfDuplicating`: `?utm_source=old&utm_medium=email` → one of each, with the new values.
- `unsplashURL_pointsToTheUnsplashHomePageWithReferralItems`: host `unsplash.com`, path `/`, the two items.

## Acceptance

- Tests above pass; `swift test` green, lint clean.

## Decision log

- Links to the Photographer and to Unsplash carry `utm_source=gallery_ios&utm_medium=referral`, as the API guidelines require. `UnsplashAttribution` builds them in Core; the app name comes from the composition root.

## Commit

`feat(core): build Unsplash referral links for the credit`
