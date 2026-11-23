import CoreGraphics
import Foundation
import GalleryImageLoading

struct ImageRequest: Equatable, Hashable {
    let url: URL
    let maxPixelSize: Int
}

final class ImageLoaderStub: ImageLoader, @unchecked Sendable {
    private let lock = NSLock()
    private let result: Result<CGImage, Error>
    private var _requests: [ImageRequest] = []

    var requests: [ImageRequest] { lock.withLock { _requests } }

    init(result: Result<CGImage, Error>) {
        self.result = result
    }

    func loadImage(from url: URL, maxPixelSize: Int) async throws -> CGImage {
        lock.withLock { _requests.append(ImageRequest(url: url, maxPixelSize: maxPixelSize)) }
        return try result.get()
    }
}
