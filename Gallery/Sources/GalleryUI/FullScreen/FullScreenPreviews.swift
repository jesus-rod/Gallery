#if DEBUG
    import CoreGraphics
    import Foundation
    import GalleryCore
    import SwiftUI

    private let previewPhotos = PreviewData.photos(1...12)

    private let previewRoute = FullScreenRoute(
        photo: previewPhotos[6],
        gridSize: ImageSize(points: 180, scale: 2),
        streamID: "feed"
    )

    private let failingImages = PhotoImages(
        preview: PreviewData.images.preview,
        cachedImage: { _, _ in nil },
        image: { _, _ in throw URLError(.notConnectedToInternet) },
        fullScreenImage: { _, _ in throw URLError(.notConnectedToInternet) },
        prefetch: { _, _ in }
    )

    #Preview("Full screen") {
        @Previewable @State var currentID = previewRoute.photo.id
        FullScreenPhotoView(
            route: previewRoute,
            photos: previewPhotos,
            images: PreviewData.images,
            referralAppName: PreviewData.referralAppName,
            currentID: $currentID
        )
    }

    #Preview("Full screen, accessibility XXXL") {
        @Previewable @State var currentID = previewRoute.photo.id
        FullScreenPhotoView(
            route: previewRoute,
            photos: previewPhotos,
            images: PreviewData.images,
            referralAppName: PreviewData.referralAppName,
            currentID: $currentID
        )
        .dynamicTypeSize(.accessibility5)
    }

    #Preview("Chrome over a bright photo") {
        @Previewable @State var isInfoPresented = false
        let photo = previewRoute.photo
        FullScreenChromeLayer(
            caption: caption(for: photo),
            photographer: photo.photographer,
            shareURL: shareURL(for: photo, appName: PreviewData.referralAppName),
            appName: PreviewData.referralAppName,
            isVisible: true,
            isInfoPresented: $isInfoPresented
        )
        .background(LinearGradient(colors: [.white, .yellow], startPoint: .top, endPoint: .bottom))
    }

    #Preview("Info sheet") {
        Color.black
            .sheet(isPresented: .constant(true)) {
                PhotoInfoSheet(
                    details: PhotoDetails(previewRoute.photo),
                    photographer: previewRoute.photo.photographer,
                    appName: PreviewData.referralAppName
                )
            }
    }

    #Preview("Full screen, image failed") {
        @Previewable @State var currentID = previewRoute.photo.id
        FullScreenPhotoView(
            route: previewRoute,
            photos: previewPhotos,
            images: failingImages,
            referralAppName: PreviewData.referralAppName,
            currentID: $currentID
        )
    }
#endif
