import CoreGraphics
import Foundation
import ImageIO

public struct DownsamplingImageLoader: ImageLoader {
    public enum Error: Swift.Error, Equatable {
        case invalidImageData
    }

    private let dataLoader: ImageDataLoader

    public init(dataLoader: ImageDataLoader) {
        self.dataLoader = dataLoader
    }

    public func loadImage(from url: URL, maxPixelSize: Int) async throws -> CGImage {
        let data = try await dataLoader.loadImageData(from: url)
        try Task.checkCancellation()
        return try Self.downsample(data, maxPixelSize: maxPixelSize)
    }

    private static func downsample(_ data: Data, maxPixelSize: Int) throws -> CGImage {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            throw Error.invalidImageData
        }
        let thumbnailOptions =
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            throw Error.invalidImageData
        }
        return image
    }
}
