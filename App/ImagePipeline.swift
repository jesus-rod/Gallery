import Foundation
import GalleryCore
import GalleryImageLoading
import GalleryUI

final class ImagePipeline: Sendable {
    private let configuration: ImagePipelineConfiguration
    private let memoryCache: MemoryCachingImageLoader
    private let prefetcher: ImagePrefetcher
    private let previews: PreviewCache
    private let store: FileImageDataStore

    init(fetch: @escaping RemoteImageDataLoader.Fetch, directory: URL, configuration: ImagePipelineConfiguration) {
        self.configuration = configuration
        store = FileImageDataStore(directory: directory)
        let remote = RemoteImageDataLoader(fetch: fetch)
        let deduplicated = InFlightDedupImageDataLoader(decoratee: remote)
        let diskCached = DiskCachingImageDataLoader(decoratee: deduplicated, store: store)
        let decoded = DownsamplingImageLoader(dataLoader: diskCached)
        memoryCache = MemoryCachingImageLoader(decoratee: decoded, costLimit: configuration.memoryCostLimit)
        prefetcher = ImagePrefetcher(loader: memoryCache)
        previews = PreviewCache(size: configuration.previewSize)
    }

    var photoImages: PhotoImages {
        PhotoImages(
            preview: { [previews] photo in photo.blurHash.flatMap(previews.preview(for:)) },
            image: { [memoryCache, configuration] photo, size in
                let rendition = Self.rendition(for: photo, size: size, configuration: configuration)
                return try await memoryCache.loadImage(from: rendition.url, maxPixelSize: rendition.maxPixelSize)
            },
            fullScreenImage: { [memoryCache, configuration] photo, size in
                let rendition = UnsplashRendition.fullScreen(
                    for: photo, fitting: size.width, height: size.height, scale: size.scale,
                    quality: configuration.fullScreenRenditionQuality)
                return try await memoryCache.loadImage(from: rendition.url, maxPixelSize: rendition.maxPixelSize)
            },
            prefetch: { [prefetcher, configuration] photos, size in
                prefetcher.prefetch(
                    photos.map { photo in
                        let rendition = Self.rendition(for: photo, size: size, configuration: configuration)
                        return ImagePrefetcher.Request(url: rendition.url, maxPixelSize: rendition.maxPixelSize)
                    })
            },
            prefetchDistance: configuration.prefetchDistance
        )
    }

    func evictDiskCache() {
        Task.detached(priority: .background) { [store, configuration] in
            try? await store.evict(toFit: configuration.diskByteLimit)
        }
    }

    func clearMemoryCache() {
        memoryCache.removeAll()
    }

    private static func rendition(
        for photo: Photo, size: ImageSize, configuration: ImagePipelineConfiguration
    ) -> UnsplashRendition.Sized {
        UnsplashRendition.grid(
            for: photo, side: size.points, scale: size.scale, quality: configuration.renditionQuality)
    }
}
