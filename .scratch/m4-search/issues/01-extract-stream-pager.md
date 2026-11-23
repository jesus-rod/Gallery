# 01 — Extract `StreamPager` from `GalleryViewModel`

Status: done
Blocked by: none

Pure refactor, no behaviour change. Move the paging state machine (state, stored `loadMore`, generation guard, load-more threshold) out of `GalleryViewModel` into an internal `@Observable @MainActor final class StreamPager`, so ticket 02 can create one pager per Query. `GalleryViewModel` keeps its exact public API and delegates to a `feedPager`. No new tests: the existing `GalleryViewModelTests` are the safety net and must stay green without edits.

## Files

- New: `Gallery/Sources/GalleryUI/Gallery/StreamPager.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryViewModel.swift`
- Edit: `docs/decision-log.md` (add the `## M4 — Search` heading at the end)

## Shape

`StreamPager.swift` (move the bodies from today's view model; only names change):

```swift
import GalleryCore
import Observation

@MainActor
@Observable
final class StreamPager {
    typealias LoadFirstPage = @Sendable () async throws -> Paginated<Photo>

    private(set) var state: StreamState = .loading

    @ObservationIgnored private let loadFirstPage: LoadFirstPage
    @ObservationIgnored private var loadMore: Paginated<Photo>.LoadMore?
    @ObservationIgnored private var generation = 0

    init(loadFirstPage: @escaping LoadFirstPage)

    func load() async
    func refresh() async -> LoadError?
    func retry() async
    func photoAppeared(_ photo: Photo) async

    private func loadMore(after photos: [Photo]) async
    private func showFirstPage(_ page: Paginated<Photo>)
    private func show(_ page: Paginated<Photo>)

    private static let loadMoreThreshold = 6
}
```

- `load()`, `retry()`, `photoAppeared(_:)`, `loadMore(after:)`, `showFirstPage(_:)`, `show(_:)`: today's `GalleryViewModel` bodies, with `feed` renamed to `state` and `loadFeed` to `loadFirstPage`.
- `refresh()`: `do { showFirstPage(try await loadFirstPage()); return nil } catch { return LoadError(error) }`.

`GalleryViewModel` after the change:

```swift
public private(set) var refreshError: LoadError?
public var feed: StreamState { feedPager.state }
@ObservationIgnored private let feedPager: StreamPager

public init(loadFeed: @escaping LoadFeed) { feedPager = StreamPager(loadFirstPage: loadFeed) }
public func load() async { await feedPager.load() }
public func refresh() async { refreshError = nil; refreshError = await feedPager.refresh() }
public func retry() async { await feedPager.retry() }
public func photoAppeared(_ photo: Photo) async { await feedPager.photoAppeared(photo) }
public func dismissRefreshError() { refreshError = nil }
```

`feedPager` is `@ObservationIgnored` because the reference never changes; `StreamPager` is itself `@Observable`, so views reading `viewModel.feed` still track `state`.

## Acceptance

- Every existing test in `Gallery/Tests/GalleryUITests/GalleryViewModelTests.swift` passes unchanged (`init_startsLoadingWithoutRequestingTheFeed` … `refresh_discardsALoadMoreThatCompletesAfterIt`).
- `GalleryViewModel` has no `loadMore`, `generation` or `loadMoreThreshold` left.
- `swift test` green, `swift format lint -r Gallery App AppUITests` clean, app still builds (`xcodebuild build …`).

## Decision log

Under a new `## M4 — Search` heading:
- The paging state machine moved into an internal `StreamPager`, so the Editorial feed and each Query's Search results run the same tested logic. It is tested through `GalleryViewModel` only.

## Commit

`refactor(ui): extract StreamPager from GalleryViewModel` with a short body saying behaviour is unchanged and why (one pager per Stream for M4).
