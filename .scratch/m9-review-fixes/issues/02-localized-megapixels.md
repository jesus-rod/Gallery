# 02 — Format megapixels with the user's locale

Status: done
Blocked by: 01

`PhotoDetails.megapixels` builds its decimal with `String(format: "%.1f", …)`. That's a C-style format (swiftui-pro rule) and ignores the locale, so a French user reads "2.5 MP" instead of "2,5 MP". The size line is shown in `PhotoInfoSheet`.

## Files

- Edit: `Gallery/Sources/GalleryUI/FullScreen/PhotoDetails.swift`
- Edit: `Gallery/Tests/GalleryUITests/PhotoDetailsTests.swift`
- Edit: `docs/decision-log.md`

## Shape

```swift
init(_ photo: Photo, locale: Locale = .current)
// megapixels: rounded.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
```

- Keep today's rounding: whole numbers from 10 MP, one decimal below; "6 MP", not "6.0 MP".
- Keep the pixel dimensions as plain digits (`6000 × 4000`), as today.
- Tests must not depend on the machine's locale (EF-31): pass `Locale(identifier: "en_US")` in the existing tests.

## Tests (one at a time, red → green)

- `describesMegapixelsWithTheLocalesDecimalSeparator` (`2500 × 1700`, `fr_FR` → `"2500 × 1700 · 4,3 MP"`)
- Existing size tests updated to pass `en_US` and still green.

## Acceptance

- `swift test` green; lint clean; no `String(format:` left in `GalleryUI` (`grep -rn "String(format" Gallery/Sources/GalleryUI`).

## Decision log

- Megapixels in Photo info use `FormatStyle` with the user's locale (injected for tests) instead of `String(format:)`, so the decimal separator follows the locale.

## Commit

`fix(ui): format megapixels with the user's locale`
