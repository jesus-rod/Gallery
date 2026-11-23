import SwiftUI

public struct GalleryRootView: View {
    private let viewModel: GalleryViewModel
    private let images: PhotoImages
    private let referralAppName: String

    @State private var searchText = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path: [FullScreenRoute] = []
    @Namespace private var zoomNamespace

    public init(viewModel: GalleryViewModel, images: PhotoImages, referralAppName: String) {
        self.viewModel = viewModel
        self.images = images
        self.referralAppName = referralAppName
    }

    public var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                feedContent
                    .opacity(isShowingSearch ? 0 : 1)
                    .allowsHitTesting(!isShowingSearch)
                    .accessibilityHidden(isShowingSearch)
                if let results = viewModel.searchResults {
                    searchContent(results)
                        .id(results.query)
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isShowingSearch)
            .safeAreaInset(edge: .top, spacing: 0) {
                if let error = viewModel.refreshError {
                    RefreshErrorBanner(error: error, onDismiss: viewModel.dismissRefreshError)
                }
            }
            .animation(.default, value: viewModel.refreshError)
            .navigationTitle(Text("Gallery", bundle: .module))
            .searchField(text: $searchText)
            .onSubmit(of: .search) {
                let query = searchText
                Task { await viewModel.search(query) }
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty { viewModel.cancelSearch() }
            }
            .navigationDestination(for: FullScreenRoute.self) { route in
                FullScreenPhotoView(route: route, images: images, referralAppName: referralAppName)
                    .zoomTransition(sourceID: route.sourceID, in: zoomNamespace)
            }
        }
        .task { await viewModel.load() }
    }

    private var isShowingSearch: Bool { viewModel.searchResults != nil }

    private func openFullScreen(_ route: FullScreenRoute) {
        path.append(route)
    }

    @ViewBuilder
    private var feedContent: some View {
        switch viewModel.feed {
        case .loading:
            SkeletonGrid()
        case .failed(let error):
            LoadErrorView(error: error) {
                Task { await viewModel.retry() }
            }
        case .loaded(let photos, let footer):
            PhotoGrid(
                photos: photos,
                footer: footer,
                images: images,
                streamID: "feed",
                zoomNamespace: zoomNamespace,
                onPhotoAppear: { photo in Task { await viewModel.photoAppeared(photo) } },
                onOpen: openFullScreen,
                onRetry: { Task { await viewModel.retry() } }
            )
            .refreshable { await viewModel.refresh() }
            .safeAreaInset(edge: .top, spacing: 0) {
                if let reason = viewModel.offlineFeedReason {
                    OfflineBanner(reason: reason)
                }
            }
        }
    }

    @ViewBuilder
    private func searchContent(_ results: SearchResults) -> some View {
        switch results.state {
        case .loading:
            SkeletonGrid()
        case .failed(let error):
            LoadErrorView(error: error) {
                Task { await viewModel.retrySearch() }
            }
        case .loaded(let photos, _) where photos.isEmpty:
            EmptySearchView(query: results.query)
        case .loaded(let photos, let footer):
            PhotoGrid(
                photos: photos,
                footer: footer,
                images: images,
                streamID: "search-\(results.query)",
                zoomNamespace: zoomNamespace,
                onPhotoAppear: { photo in Task { await viewModel.searchPhotoAppeared(photo) } },
                onOpen: openFullScreen,
                onRetry: { Task { await viewModel.retrySearch() } }
            )
            .refreshable { await viewModel.refreshSearch() }
        }
    }
}

extension View {
    fileprivate func searchField(text: Binding<String>) -> some View {
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
