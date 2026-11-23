import SwiftUI

public struct GalleryRootView: View {
    private let viewModel: GalleryViewModel
    private let images: PhotoImages
    private let referralAppName: String

    @State private var searchText = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path: [FullScreenRoute] = []
    @State private var fullScreenPhotoID = ""
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
            .animation(Design.Motion.streamSwitch(reduceMotion: reduceMotion), value: isShowingSearch)
            .safeAreaInset(edge: .top, spacing: 0) {
                if let error = viewModel.refreshError {
                    RefreshErrorBanner(error: error, onDismiss: viewModel.dismissRefreshError)
                }
            }
            .animation(.default, value: viewModel.refreshError)
            .navigationTitle(Text("Gallery", bundle: .module))
            #if os(iOS)
                .toolbarTitleDisplayMode(isHeroUnderBar ? .inline : .large)
                .toolbarColorScheme(isHeroUnderBar ? .dark : nil, for: .navigationBar)
                .toolbarBackground(isHeroUnderBar ? .visible : .automatic, for: .navigationBar)
                .toolbarBackground(
                    isHeroUnderBar ? AnyShapeStyle(Color.clear) : AnyShapeStyle(.bar),
                    for: .navigationBar
                )
                .toolbar {
                    if isHeroUnderBar {
                        floatingTitle
                    }
                }
            #endif
            .searchField(text: $searchText)
            .onSubmit(of: .search) {
                let query = searchText
                Task { await viewModel.search(query) }
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty { viewModel.cancelSearch() }
            }
            .navigationDestination(for: FullScreenRoute.self) { route in
                FullScreenPhotoView(
                    route: route,
                    photos: viewModel.photos(in: route.streamID),
                    images: images,
                    referralAppName: referralAppName,
                    currentID: $fullScreenPhotoID,
                    onPhotoAppear: { photo in
                        Task { await viewModel.photoAppeared(photo, in: route.streamID) }
                    }
                )
                .zoomTransition(
                    sourceID: FullScreenRoute.sourceID(streamID: route.streamID, photoID: fullScreenPhotoID),
                    in: zoomNamespace
                )
            }
        }
        .task { await viewModel.load() }
    }

    private var isShowingSearch: Bool { viewModel.searchResults != nil }

    private var isHeroUnderBar: Bool {
        guard !isShowingSearch, case .loaded(let photos, _) = viewModel.feed else { return false }
        return !photos.isEmpty
    }

    #if os(iOS)
        @ToolbarContentBuilder
        private var floatingTitle: some ToolbarContent {
            if #available(iOS 26, *) {
                ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) }
                    .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .topBarLeading) { floatingTitleText }
                    .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) }
                ToolbarItem(placement: .topBarLeading) { floatingTitleText }
            }
        }

        private var floatingTitleText: some View {
            Text("Gallery", bundle: .module)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 8)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
        }
    #endif

    private func focusedPhotoID(in streamID: String) -> String? {
        path.last?.streamID == streamID ? fullScreenPhotoID : nil
    }

    private func openFullScreen(_ route: FullScreenRoute) {
        fullScreenPhotoID = route.photo.id
        path.append(route)
    }

    @ViewBuilder
    private var feedContent: some View {
        switch viewModel.feed {
        case .loading:
            SkeletonGrid(showsHero: true)
        case .failed(let error):
            LoadErrorView(error: error) {
                Task { await viewModel.retry() }
            }
        case .loaded(let photos, let footer):
            PhotoGrid(
                photos: photos,
                footer: footer,
                images: images,
                streamID: GalleryViewModel.feedStreamID,
                zoomNamespace: zoomNamespace,
                focusedPhotoID: focusedPhotoID(in: GalleryViewModel.feedStreamID),
                hero: photos.first.map { PhotoGrid.Hero(photo: $0, appName: referralAppName) },
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
                streamID: GalleryViewModel.searchStreamID(for: results.query),
                zoomNamespace: zoomNamespace,
                focusedPhotoID: focusedPhotoID(in: GalleryViewModel.searchStreamID(for: results.query)),
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
            if #available(iOS 26, *) {
                searchable(text: text, prompt: Text("Search photos", bundle: .module))
            } else {
                searchable(
                    text: text,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text("Search photos", bundle: .module)
                )
            }
        #else
            searchable(text: text, prompt: Text("Search photos", bundle: .module))
        #endif
    }
}
