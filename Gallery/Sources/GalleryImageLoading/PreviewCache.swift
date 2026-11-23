import CoreGraphics
import Foundation

public final class PreviewCache: @unchecked Sendable {
    public typealias Decode = @Sendable (_ hash: String, _ width: Int, _ height: Int) -> CGImage?

    private final class Entry {
        let image: CGImage

        init(image: CGImage) {
            self.image = image
        }
    }

    private let size: Int
    private let decode: Decode
    private let cache = NSCache<NSString, Entry>()

    public init(size: Int, decode: @escaping Decode = { BlurHash.decode($0, width: $1, height: $2) }) {
        self.size = size
        self.decode = decode
    }

    public func preview(for hash: String) -> CGImage? {
        if let entry = cache.object(forKey: hash as NSString) {
            return entry.image
        }
        guard let image = decode(hash, size, size) else { return nil }
        cache.setObject(Entry(image: image), forKey: hash as NSString)
        return image
    }
}
