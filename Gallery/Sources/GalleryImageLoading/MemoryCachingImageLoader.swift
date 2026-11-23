import CoreGraphics
import Foundation

public final class MemoryCachingImageLoader: ImageLoader, @unchecked Sendable {
    private final class Entry {
        let image: CGImage

        init(image: CGImage) {
            self.image = image
        }
    }

    private let decoratee: ImageLoader
    private let cache = NSCache<NSString, Entry>()

    public init(decoratee: ImageLoader, costLimit: Int) {
        self.decoratee = decoratee
        cache.totalCostLimit = costLimit
    }

    public func loadImage(from url: URL, maxPixelSize: Int) async throws -> CGImage {
        let key = Self.key(url, maxPixelSize)
        if let entry = cache.object(forKey: key) {
            return entry.image
        }
        let image = try await decoratee.loadImage(from: url, maxPixelSize: maxPixelSize)
        cache.setObject(Entry(image: image), forKey: key, cost: image.bytesPerRow * image.height)
        return image
    }

    public func cachedImage(from url: URL, maxPixelSize: Int) -> CGImage? {
        cache.object(forKey: Self.key(url, maxPixelSize))?.image
    }

    public func removeAll() {
        cache.removeAllObjects()
    }

    private static func key(_ url: URL, _ maxPixelSize: Int) -> NSString {
        "\(maxPixelSize)|\(url.absoluteString)" as NSString
    }
}
