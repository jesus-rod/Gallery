# code-review

Status: ready-for-agent

Whole-project /code-review (Standards + Spec) from the first commit; fix confirmed findings, one commit each; list skipped ones with the reason in Comments.

## Comments

Run on 2026-11-23 over `8711075..HEAD` (Standards + Spec, two parallel reviewers).

Fixed:
- Duplicated stream wiring in the composition root → one `makeStream` helper (`a99b214`).
- Empty `GalleryUITests.swift` removed; `HTTPURLResponse+RateLimit.swift` renamed `+Unsplash` (`af05606`).
- Search refresh not cancellable, and refresh racing an in-flight load more → refresh is the pager's one cancellable request (`d55c034`, 3 new tests).
- No feed↔search transition → 0.2 s cross-fade, none with Reduce Motion (`d57f26c`).

Accepted (judgement calls, not worth the churn now):
- Cell keeps its previous image scaled after a size change until the new Rendition loads (logged).
- `UnsplashRendition.fullScreen` takes loose `Double`s: `FittingSize` lives in GalleryUI and Core can't import it.
- Feed/search `switch` duplication in `GalleryRootView`, the memoised `CGImage??` getters, raw `String` Query, launch-argument strings, `GalleryViewModel` forwarding to `StreamPager` (a façade over an internal type).
- `.timedOut` mapped to `.offline`: a timeout reads as a connection problem to the user.
- Four XCUITests: offline is its own journey (logged in M6).

Open, needs the user: the grid shows no visible Caption (VoiceOver label only), which the brief asks for.
