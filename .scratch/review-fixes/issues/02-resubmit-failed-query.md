# 02 — Re-submitting a failed Query searches again

Status: done
Blocked by: 01

`search(_:)` skips a Query equal to the one shown (`query != activeSearch?.query`), which saves the Request budget. It also skips it when that Query's first Page failed, so pressing Search again does nothing and only the Retry button works. Re-submitting should search again when the shown Query's state is `.failed`; it stays a no-op while loading or loaded.

## Files

- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryViewModel.swift`
- Edit: `Gallery/Tests/GalleryUITests/GalleryViewModelTests.swift`
- Edit: `docs/decision-log.md`

## Tests (one at a time, red → green)

- `search_sameQueryAfterAFailedFirstPageSearchesAgain` (cats fails, submit "cats" again → second search call, results shown)
- `search_sameQueryWhileLoadingDoesNothing` (keep or add: no second call while the first is gated)
- Existing `search_sameQueryAsTheOneShownDoesNothing` stays green for the loaded case.

## Acceptance

- Tests pass; `swift test` green; lint clean.

## Decision log

- Re-submitting the shown Query is still a no-op, except after its first Page failed: then it searches again, like Retry.

## Commit

`fix(ui): search again when the shown Query failed`

## Comments

- `search_sameQueryWhileLoadingDoesNothing` was not added: the existing `search_sameQueryWhileItLoadsDoesNotCancelIt` already asserts that no second request is sent while the first Page loads.
