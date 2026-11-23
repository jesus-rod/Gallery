#if DEBUG
    import CoreGraphics
    import Foundation
    import GalleryCore
    import SwiftUI

    private let previewRoute = FullScreenRoute(
        photo: PreviewData.photos(7...7)[0],
        gridSize: ImageSize(points: 180, scale: 2),
        sourceID: "feed-7"
    )

    private let failingImages = PhotoImages(
        preview: PreviewData.images.preview,
        cachedImage: { _, _ in nil },
        image: { _, _ in throw URLError(.notConnectedToInternet) },
        fullScreenImage: { _, _ in throw URLError(.notConnectedToInternet) },
        prefetch: { _, _ in }
    )

    #Preview("Full screen") {
        FullScreenPhotoView(
            route: previewRoute,
            images: PreviewData.images,
            referralAppName: PreviewData.referralAppName
        )
    }

    #Preview("Full screen, image failed") {
        FullScreenPhotoView(
            route: previewRoute,
            images: failingImages,
            referralAppName: PreviewData.referralAppName
        )
    }
#endif
