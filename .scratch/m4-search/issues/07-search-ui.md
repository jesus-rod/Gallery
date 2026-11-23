# 07 — Search UI: field, results, empty state, feed kept alive

Status: done
Blocked by: 05, 06

`GalleryRootView` gets a search field and shows Search results over the Editorial feed. The feed view stays in the hierarchy while hidden, so its scroll position survives. Views stay logic-free: no unit tests here; check with `#Preview`s and a manual `-useStubs` run, and ticket 08 adds the XCUITests.

## Files

- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryRootView.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/StateViews.swift` (add `EmptySearchView`)
- Edit: `Gallery/Sources/GalleryUI/Localizable.xcstrings`
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryPreviews.swift`
- Edit: `docs/decision-log.md`

## Shape

`GalleryRootView`:

```swift
@State private var searchText = ""

public var body: some View {
    NavigationStack {
        ZStack {
            feedContent
                .opacity(isShowingSearch ? 0 : 1)
                .allowsHitTesting(!isShowingSearch)
                .accessibilityHidden(isShowingSearch)
            if let results = viewModel.searchResults {
                searchContent(results)
                    .id(results.query)
            }
        }
        .navigationTitle(Text("Gallery", bundle: .module))
        .searchField(text: $searchText)
        .onSubmit(of: .search) {
            let query = searchText
            Task { await viewModel.search(query) }
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty { viewModel.cancelSearch() }
        }
    }
    .task { await viewModel.load() }
}

private var isShowingSearch: Bool { viewModel.searchResults != nil }
```

- `feedContent` is today's `content` renamed, unchanged (feed `PhotoGrid`, `.refreshable`, refresh banner).
- `searchContent(_ results: SearchResults)` is a `@ViewBuilder` `switch results.state`:
  - `.loading` → `SkeletonGrid()`
  - `.failed(let error)` → `LoadErrorView(error: error) { Task { await viewModel.retrySearch() } }`
  - `.loaded(let photos, _) where photos.isEmpty` → `EmptySearchView(query: results.query)`
  - `.loaded(let photos, let footer)` → `PhotoGrid(photos: photos, footer: footer, images: images, onPhotoAppear: { photo in Task { await viewModel.searchPhotoAppeared(photo) } }, onRetry: { Task { await viewModel.retrySearch() } })`. No `.refreshable`. Same `images` as the feed.
- `searchField(text:)` is a `private extension View` in the same file, because `navigationBarDrawer` does not exist on macOS (the package builds for macOS in `swift test`):

```swift
private extension View {
    func searchField(text: Binding<String>) -> some View {
        #if os(iOS)
            searchable(
                text: text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("Search photos", bundle: .module)
            )
        #else
            searchable(text: text, prompt: Text("Search photos", bundle: .module))
        #endif
    }
}
```

`EmptySearchView` in `StateViews.swift`:

```swift
struct EmptySearchView: View {
    let query: String

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "No photos for “\(query)”", bundle: .module), systemImage: "magnifyingglass")
        } description: {
            Text("Try a different search.", bundle: .module)
        }
        .accessibilityIdentifier("search-empty")
    }
}
```

`Localizable.xcstrings`: add three entries in the existing style (keys sorted alphabetically like the file, `state: translated`, an English `value` equal to the key):
- `"No photos for “%@”"`, comment "Title shown when a search finds no photos; the argument is the Query."
- `"Search photos"`, comment "Prompt in the search field above the grid."
- `"Try a different search."`, comment "Message shown when a search finds no photos."

`GalleryPreviews.swift`: add
- `#Preview("Search results")`: `let viewModel = PreviewData.viewModel { Paginated(items: PreviewData.photos(1...30)) }` then `GalleryRootView(viewModel: viewModel, images: PreviewData.images).task { await viewModel.search("cats") }`.
- `#Preview("No search results")`: `EmptySearchView(query: "cats")`.

## Acceptance

- `swift test` green (GalleryUI still compiles for macOS); `swift format lint -r Gallery App AppUITests` clean; `xcodebuild build …` succeeds.
- Manual, iPhone 17 Pro simulator, app launched with `-useStubs`: the search field is visible above the grid; submitting "cats" shows "Cat fixture photo" cells; "zzzz" shows "No photos for “zzzz”"; scrolling the feed down, searching, then tapping Cancel returns to the same feed position. Note the result under `## Comments`.
- XCUITests for these flows: ticket 08.

## Decision log

- The feed view stays in a `ZStack` under Search results, hidden with opacity, hit testing and accessibility off, so its scroll position survives a search without storing it by hand.
- Clearing the search field (or Cancel, which clears it) returns to the feed; the search field is always visible (`navigationBarDrawer(displayMode: .always)`).
- Each Query's grid gets `.id(query)`, so new results start at the top.

## Commit

`feat(ui): add the search field and show Search results over the feed`.
