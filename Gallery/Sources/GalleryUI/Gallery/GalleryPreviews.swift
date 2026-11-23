#if DEBUG
    import Foundation
    import GalleryCore
    import SwiftUI

    enum PreviewData {
        static let referralAppName = "gallery_ios"

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

        static let images = PhotoImages(
            preview: { photo in solidImage(hue: hue(of: photo), brightness: 0.5) },
            image: { photo, _ in try await loadedImage(of: photo) },
            fullScreenImage: { photo, _ in try await loadedImage(of: photo) },
            prefetch: { _, _ in }
        )

        private static func loadedImage(of photo: Photo) async throws -> CGImage {
            try await Task.sleep(for: .milliseconds(Int.random(in: 300...1500)))
            guard let image = solidImage(hue: hue(of: photo), brightness: 0.85) else { throw URLError(.unknown) }
            return image
        }

        private static func hue(of photo: Photo) -> CGFloat {
            CGFloat((Int(photo.id) ?? 0) % 12) / 12
        }

        private static func solidImage(hue: CGFloat, brightness: CGFloat) -> CGImage? {
            let context = CGContext(
                data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            let color = Color(hue: hue, saturation: 0.5, brightness: brightness).resolve(in: EnvironmentValues())
            context?.setFillColor(
                CGColor(srgbRed: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: 1))
            context?.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
            return context?.makeImage()
        }

        @MainActor
        static func viewModel(
            offlineFeed: [Photo] = [],
            _ load: @escaping GalleryViewModel.LoadFeed
        ) -> GalleryViewModel {
            GalleryViewModel(
                loadFeed: load,
                loadOfflineFeed: { offlineFeed },
                search: { _ in Paginated(items: PreviewData.photos(31...42)) })
        }
    }

    #Preview("Loaded") {
        GalleryRootView(
            viewModel: PreviewData.viewModel { Paginated(items: PreviewData.photos(1...30)) },
            images: PreviewData.images, referralAppName: PreviewData.referralAppName)
    }

    #Preview("Loading") {
        GalleryRootView(
            viewModel: PreviewData.viewModel {
                try await Task.sleep(for: .seconds(3600))
                return Paginated(items: [])
            },
            images: PreviewData.images,
            referralAppName: PreviewData.referralAppName
        )
    }

    #Preview("Offline") {
        GalleryRootView(
            viewModel: PreviewData.viewModel { throw URLError(.notConnectedToInternet) }, images: PreviewData.images,
            referralAppName: PreviewData.referralAppName)
    }

    #Preview("Offline feed") {
        GalleryRootView(
            viewModel: PreviewData.viewModel(offlineFeed: PreviewData.photos(1...12)) {
                throw URLError(.notConnectedToInternet)
            },
            images: PreviewData.images,
            referralAppName: PreviewData.referralAppName)
    }

    #Preview("Offline banners") {
        VStack {
            OfflineBanner(reason: .offline)
            OfflineBanner(reason: .rateLimited)
        }
    }

    #Preview("Rate limited") {
        GalleryRootView(
            viewModel: PreviewData.viewModel { throw UnsplashAPIError.rateLimited }, images: PreviewData.images,
            referralAppName: PreviewData.referralAppName)
    }

    #Preview("Search results") {
        let viewModel = PreviewData.viewModel { Paginated(items: PreviewData.photos(1...30)) }
        GalleryRootView(viewModel: viewModel, images: PreviewData.images, referralAppName: PreviewData.referralAppName)
            .task { await viewModel.search("cats") }
    }

    #Preview("No search results") {
        EmptySearchView(query: "cats")
    }

    #Preview("Footer states") {
        VStack {
            FooterView(footer: .loading, onRetry: {})
            FooterView(footer: .failed(.offline), onRetry: {})
        }
    }
#endif
