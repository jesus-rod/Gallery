# 01 — Cancel every in-flight request of an old search

Status: done
Blocked by: none

Today only the first-Page load runs in `searchTask`, so `cancelSearch()` and a new Query cancel that and nothing else. A search load more or a `retrySearch()` in flight keeps its request running; the result is discarded (the pager is unreferenced) but the request still costs Request budget. M4 spec: "Submitting "dogs" while "cats" is still loading cancels the "cats" request" and "Any in-flight search is cancelled and its result discarded."

## Files

- Edit: `Gallery/Sources/GalleryUI/Gallery/StreamPager.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryViewModel.swift`
- Edit: `Gallery/Tests/GalleryUITests/Helpers/FeedLoaderSpy.swift`
- Edit: `Gallery/Tests/GalleryUITests/GalleryViewModelTests.swift`
- Edit: `docs/decision-log.md` (create `## Review fixes (M3, M4)`)

## Shape

The pager owns its requests, so the view model can cancel a whole Stream with one call.

```swift
final class StreamPager {
    @ObservationIgnored private var inFlight: Task<Void, Never>?
    func cancel()          // inFlight?.cancel(); inFlight = nil; generation += 1
}
```

- `load()`, `retry()` and `photoAppeared(_:)` run their request inside a `Task` stored in `inFlight` and `await` its value, so callers keep awaiting as today.
- `cancel()` cancels that task and bumps `generation`, so a result that still arrives is ignored by the existing generation guard.
- `GalleryViewModel.search(_:)` and `cancelSearch()` call `activeSearch?.pager.cancel()` before replacing or dropping the search. `searchTask` goes away if nothing else needs it.
- The feed pager is never cancelled by search (unchanged behaviour; keep the existing isolation tests green).

Spy: record cancellation for load more too, the same way `search` does: after the gate, `if Task.isCancelled { cancelledLoadMoreCount += 1 }`.

## Tests (one at a time, red → green)

- `search_cancelsTheLoadMoreOfThePreviousQuery` (cats loaded, load more gated in flight, submit dogs, open gate → `cancelledLoadMoreCount == 1`, Search results show dogs)
- `search_cancelsTheRetryOfThePreviousQuery` (cats first Page failed, `retrySearch()` gated, submit dogs → the retried "cats" call saw cancellation)
- `cancelSearch_cancelsAnInFlightSearchLoadMore`
- `cancelSearch_cancelsAnInFlightSearchRetry`
- `cancelSearch_doesNotCancelTheFeedsLoadMore` (feed load more gated, search, cancel search, open gate → `cancelledLoadMoreCount == 0`, feed shows the appended Page)

## Acceptance

- New tests and all existing `GalleryViewModelTests` pass; `swift test` green; lint clean; app builds.

## Decision log

- Each `StreamPager` owns its in-flight request and can cancel it. A new Query or Cancel cancels every request of the old search (first Page, load more, retry), not just its first Page, so an abandoned search stops spending the Request budget.

## Commit

`fix(ui): cancel every in-flight request of an abandoned search`

## Comments

- Only the first test (load more) was seen red. The retry, cancel-retry, cancel-load-more and feed-isolation tests passed on their first run, because `StreamPager.run` wraps every request path once the first test is green. They stay as regression tests.
- `cancelSearch_doesNotCancelTheFeedsLoadMore` overlaps the existing `cancelSearch_keepsTheFeedLoadMoreRunning`; it is kept because the ticket lists it and it asserts the new cancellation counter.
