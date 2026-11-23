import SwiftUI

public struct GalleryRootView: View {
    private let viewModel: GalleryViewModel

    public init(viewModel: GalleryViewModel) {
        self.viewModel = viewModel
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
