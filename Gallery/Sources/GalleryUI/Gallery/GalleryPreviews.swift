#if DEBUG
    import Foundation
    import GalleryCore
    import SwiftUI

    private enum PreviewData {
        static func photos(_ range: ClosedRange<Int>) -> [Photo] {
            range.map { index in
                let url = URL(filePath: "/preview/\(index)")
                return Photo(
                    id: "\(index)",
                    width: 1,
                    height: 1,
                    blurHash: nil,
                    description: nil,
                    altDescription: "Preview photo \(index)",
                    renditions: Photo.Renditions(raw: url, small: url, regular: url),
                    photographer: Photo.Photographer(name: "A photographer", profileURL: url)
                )
            }
        }

        @MainActor
        static func viewModel(_ load: @escaping GalleryViewModel.LoadFeed) -> GalleryViewModel {
            GalleryViewModel(loadFeed: load)
        }
    }

    #Preview("Loaded") {
        GalleryRootView(viewModel: PreviewData.viewModel { Paginated(items: PreviewData.photos(1...30)) })
    }

    #Preview("Loading") {
        GalleryRootView(
            viewModel: PreviewData.viewModel {
                try await Task.sleep(for: .seconds(3600))
                return Paginated(items: [])
            })
    }

    #Preview("Offline") {
        GalleryRootView(viewModel: PreviewData.viewModel { throw URLError(.notConnectedToInternet) })
    }

    #Preview("Rate limited") {
        GalleryRootView(viewModel: PreviewData.viewModel { throw UnsplashAPIError.rateLimited })
    }

    #Preview("Footer states") {
        VStack {
            FooterView(footer: .loading, onRetry: {})
            FooterView(footer: .failed(.offline), onRetry: {})
        }
    }
#endif
