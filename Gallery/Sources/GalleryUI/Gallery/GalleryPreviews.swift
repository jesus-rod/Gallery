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

        static let images = PhotoImages(
            preview: { photo in solidImage(hue: hue(of: photo), brightness: 0.5) },
            image: { photo, _ in
                try await Task.sleep(for: .milliseconds(Int.random(in: 300...1500)))
                guard let image = solidImage(hue: hue(of: photo), brightness: 0.85) else { throw URLError(.unknown) }
                return image
            },
            prefetch: { _, _ in }
        )

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
        static func viewModel(_ load: @escaping GalleryViewModel.LoadFeed) -> GalleryViewModel {
            GalleryViewModel(loadFeed: load)
        }
    }

    #Preview("Loaded") {
        GalleryRootView(
            viewModel: PreviewData.viewModel { Paginated(items: PreviewData.photos(1...30)) },
            images: PreviewData.images)
    }

    #Preview("Loading") {
        GalleryRootView(
            viewModel: PreviewData.viewModel {
                try await Task.sleep(for: .seconds(3600))
                return Paginated(items: [])
            },
            images: PreviewData.images
        )
    }

    #Preview("Offline") {
        GalleryRootView(
            viewModel: PreviewData.viewModel { throw URLError(.notConnectedToInternet) }, images: PreviewData.images)
    }

    #Preview("Rate limited") {
        GalleryRootView(
            viewModel: PreviewData.viewModel { throw UnsplashAPIError.rateLimited }, images: PreviewData.images)
    }

    #Preview("Footer states") {
        VStack {
            FooterView(footer: .loading, onRetry: {})
            FooterView(footer: .failed(.offline), onRetry: {})
        }
    }
#endif
