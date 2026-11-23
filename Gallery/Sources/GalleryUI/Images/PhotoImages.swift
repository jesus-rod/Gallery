import CoreGraphics
import GalleryCore

public struct ImageSize: Hashable, Sendable {
    public let points: Double
    public let scale: Double

    public init(points: Double, scale: Double) {
        self.points = points
        self.scale = scale
    }

    public var pixels: Int {
        Int((points * scale).rounded(.up))
    }
}

public struct PhotoImages: Sendable {
    public typealias Preview = @Sendable (Photo) -> CGImage?
    public typealias LoadImage = @Sendable (Photo, ImageSize) async throws -> CGImage
    public typealias Prefetch = @Sendable ([Photo], ImageSize) -> Void

    let preview: Preview
    let image: LoadImage
    let prefetch: Prefetch
    let prefetchDistance: Int

    public init(
        preview: @escaping Preview,
        image: @escaping LoadImage,
        prefetch: @escaping Prefetch,
        prefetchDistance: Int = 9
    ) {
        self.preview = preview
        self.image = image
        self.prefetch = prefetch
        self.prefetchDistance = prefetchDistance
    }
}

func prefetchWindow(after photo: Photo, in photos: [Photo], distance: Int) -> ArraySlice<Photo> {
    guard let index = photos.firstIndex(where: { $0.id == photo.id }) else { return [] }
    let start = index + 1
    return photos[start..<min(start + distance, photos.endIndex)]
}
