import SwiftUI

public struct GalleryRootView: View {
    private let viewModel: GalleryViewModel
    private let images: PhotoImages

    @State private var searchText = ""

    public init(viewModel: GalleryViewModel, images: PhotoImages) {
        self.viewModel = viewModel
        self.images = images
    }

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
                onPhotoAppear: { photo in Task { await viewModel.photoAppeared(photo) } },
                onRetry: { Task { await viewModel.retry() } }
            )
            .refreshable { await viewModel.refresh() }
            .overlay(alignment: .top) {
                if let error = viewModel.refreshError {
                    RefreshErrorBanner(error: error, onDismiss: viewModel.dismissRefreshError)
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
                onPhotoAppear: { photo in Task { await viewModel.searchPhotoAppeared(photo) } },
                onRetry: { Task { await viewModel.retrySearch() } }
            )
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
