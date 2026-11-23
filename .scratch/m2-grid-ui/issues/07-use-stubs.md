# 07 — `-useStubs` launch path

Status: done
Blocked by: 06

`StubHTTPClient` in the app target answers Editorial page N with bundled `editorial-page-N.json` (two pages of 30), and an empty array beyond. The `-useStubs` launch argument selects it in the composition root instead of the authorized client.

## Acceptance
- Unit-tested response mapping (page 1, page 2, page 3 → empty).
- App launched with `-useStubs` shows fixture Photos with no network and no key.

## Comments

- `StubHTTPClient` lives in the app target, which has no unit test target. Its page mapping is covered end to end by the XCUITests in 08 (page 1 on launch, page 2 on scroll) instead of a unit test. Compiled in Debug only; the fixture JSON is still copied into Release bundles (synchronized groups have no per-configuration membership).
- The `App` group is now a synchronized folder group (Info.plist excluded), and the target gained a Resources phase, so new app files need no project edits.
