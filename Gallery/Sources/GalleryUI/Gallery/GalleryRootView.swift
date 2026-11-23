import SwiftUI

public struct GalleryRootView: View {
    private let viewModel: GalleryViewModel
    private let images: PhotoImages

    public init(viewModel: GalleryViewModel, images: PhotoImages) {
        self.viewModel = viewModel
        self.images = images
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text("Gallery", bundle: .module))
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
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
}
