import CoreGraphics
import Foundation
import GalleryCore
import Testing

@testable import GalleryUI

@MainActor
@Suite(.trackingLeaks)
struct PhotoImageModelTests {
    private let size = ImageSize(points: 100, scale: 2)

    @Test func init_doesNotLookUpThePreview() {
        let (_, images) = makeSUT(preview: makeImage())

        #expect(images.previewCallCount == 0)
    }

    @Test func preview_isLookedUpOnceOnFirstRead() {
        let (sut, images) = makeSUT(preview: makeImage())

        _ = sut.preview
        _ = sut.preview

        #expect(images.previewCallCount == 1)
    }

    @Test func init_showsThePhotosPreview() {
        let preview = makeImage()
        let (sut, _) = makeSUT(preview: preview)

        #expect(sut.preview == preview)
    }

    @Test func init_showsNoPreviewWhenThereIsNone() {
        let (sut, _) = makeSUT(preview: nil)

        #expect(sut.preview == nil)
    }

    @Test func load_requestsThePhotoAtTheGivenSize() async {
        let photo = makePhoto(id: "a")
        let (sut, images) = makeSUT(photo: photo)

        await sut.load(size: size)

        #expect(images.requests == [PhotoImagesSpy.Request(photoID: "a", size: size)])
    }

    @Test func load_showsTheLoadedImage() async {
        let image = makeImage()
        let (sut, images) = makeSUT()
        images.stub(.success(image))

        await sut.load(size: size)

        #expect(sut.image == image)
    }

    @Test func load_showsTheLoadedImageAndKeepsThePreview() async {
        let preview = makeImage()
        let image = makeImage(width: 2)
        let (sut, images) = makeSUT(preview: preview)
        images.stub(.success(image))

        await sut.load(size: size)

        #expect(sut.image == image)
        #expect(sut.preview == preview)
    }

    @Test func load_keepsNoImageOnFailure() async {
        let preview = makeImage()
        let (sut, images) = makeSUT(preview: preview)
        images.stub(.failure(AnyError()))

        await sut.load(size: size)

        #expect(sut.image == nil)
        #expect(sut.preview == preview)
    }

    @Test func load_keepsTheLoadedImageWhenALaterLoadFails() async {
        let image = makeImage()
        let (sut, images) = makeSUT()
        images.stub(.success(image))
        await sut.load(size: size)

        images.stub(.failure(AnyError()))
        await sut.load(size: ImageSize(points: 200, scale: 2))

        #expect(sut.image == image)
    }

    @Test func load_cancelledLeavesTheImageUnchanged() async {
        let gate = Gate()
        let (sut, images) = makeSUT()
        images.stub(.success(makeImage()), gate: gate)

        let load = Task { await sut.load(size: size) }
        await gate.untilReached()
        load.cancel()
        gate.open()
        await load.value

        #expect(sut.image == nil)
    }

    @Test func isLoaded_isTrueOnlyOnceTheImageIsShown() async {
        let (sut, images) = makeSUT(preview: makeImage())
        #expect(sut.isLoaded == false)

        images.stub(.success(makeImage()))
        await sut.load(size: size)

        #expect(sut.isLoaded == true)
    }

    @Test func image_isTheCachedImageBeforeAnyLoad() {
        let cached = makeImage(width: 3)
        let (sut, _) = makeSUT(cached: cached)

        #expect(sut.image == cached)
        #expect(sut.isLoaded == true)
    }

    @Test func load_requestsNothingWhenTheImageIsCached() async {
        let (sut, images) = makeSUT(cached: makeImage())

        await sut.load(size: size)

        #expect(images.requests.isEmpty)
    }

    @Test func image_isLookedUpOnceHoweverOftenItIsRead() {
        let (sut, images) = makeSUT(cached: makeImage())

        _ = sut.image
        _ = sut.image
        _ = sut.isLoaded

        #expect(images.cachedImageRequests == [PhotoImagesSpy.Request(photoID: "any-id", size: size)])
    }

    @Test func init_doesNotLookUpTheCachedImage() {
        let (_, images) = makeSUT(cached: makeImage())

        #expect(images.cachedImageRequests.isEmpty)
    }

    @Test func wasCachedOnAppear_isTrueOnlyWhenTheImageWasCachedBeforeAnyLoad() async {
        let (cachedSUT, _) = makeSUT(cached: makeImage())
        let (lateSUT, images) = makeSUT()
        images.stub(.success(makeImage()))
        await lateSUT.load(size: size)

        #expect(cachedSUT.wasCachedOnAppear == true)
        #expect(lateSUT.wasCachedOnAppear == false)
    }

    @Test func release_dropsTheLoadedImage() async {
        let (sut, images) = makeSUT()
        images.stub(.success(makeImage()))
        await sut.load(size: size)

        sut.release()

        #expect(sut.image == nil)
        #expect(!sut.isLoaded)
    }

    @Test func release_asksTheCacheAgainOnTheNextRead() {
        let cached = makeImage()
        let (sut, images) = makeSUT(cached: cached)
        _ = sut.image

        sut.release()

        #expect(sut.image == cached)
        #expect(images.cachedImageRequests.count == 2)
    }

    private func makeSUT(
        photo: Photo = makePhoto(),
        preview: CGImage? = nil,
        cached: CGImage? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (PhotoImageModel, PhotoImagesSpy) {
        let spy = PhotoImagesSpy(preview: preview, cached: cached)
        let sut = PhotoImageModel(photo: photo, images: spy.images, size: size)
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        trackForMemoryLeaks(spy, sourceLocation: sourceLocation)
        return (sut, spy)
    }
}

final class PhotoImagesSpy: @unchecked Sendable {
    struct Request: Equatable {
        let photoID: String
        let size: ImageSize
    }

    struct FullScreenRequest: Equatable {
        let photoID: String
        let size: FittingSize
    }

    struct Prefetch: Equatable {
        let photoIDs: [String]
        let size: ImageSize
    }

    private let lock = NSLock()
    private let preview: CGImage?
    private let cached: CGImage?
    private var result: Result<CGImage, Error> = .failure(AnyError())
    private var resultGate: Gate?
    private var fullScreenResult: Result<CGImage, Error> = .failure(AnyError())
    private var fullScreenGate: Gate?
    private var _requests: [Request] = []
    private var _fullScreenRequests: [FullScreenRequest] = []
    private var _prefetches: [Prefetch] = []
    private var _previewCallCount = 0
    private var _cachedImageRequests: [Request] = []

    var requests: [Request] { lock.withLock { _requests } }
    var fullScreenRequests: [FullScreenRequest] { lock.withLock { _fullScreenRequests } }
    var prefetches: [Prefetch] { lock.withLock { _prefetches } }
    var previewCallCount: Int { lock.withLock { _previewCallCount } }
    var cachedImageRequests: [Request] { lock.withLock { _cachedImageRequests } }

    init(preview: CGImage? = nil, cached: CGImage? = nil) {
        self.preview = preview
        self.cached = cached
    }

    func stub(_ result: Result<CGImage, Error>, gate: Gate? = nil) {
        lock.withLock {
            self.result = result
            resultGate = gate
        }
    }

    func stubFullScreen(_ result: Result<CGImage, Error>, gate: Gate? = nil) {
        lock.withLock {
            fullScreenResult = result
            fullScreenGate = gate
        }
    }

    var images: PhotoImages {
        PhotoImages(
            preview: { [self] _ in
                lock.withLock { _previewCallCount += 1 }
                return preview
            },
            cachedImage: { [self] photo, size in
                lock.withLock {
                    _cachedImageRequests.append(Request(photoID: photo.id, size: size))
                    return cached
                }
            },
            image: { [self] photo, size in
                let (result, gate) = lock.withLock {
                    _requests.append(Request(photoID: photo.id, size: size))
                    return (self.result, resultGate)
                }
                await gate?.pass()
                return try result.get()
            },
            fullScreenImage: { [self] photo, size in
                let (result, gate) = lock.withLock {
                    _fullScreenRequests.append(FullScreenRequest(photoID: photo.id, size: size))
                    return (fullScreenResult, fullScreenGate)
                }
                await gate?.pass()
                return try result.get()
            },
            prefetch: { [self] photos, size in
                lock.withLock { _prefetches.append(Prefetch(photoIDs: photos.map(\.id), size: size)) }
            }
        )
    }
}

func makeImage(width: Int = 1, height: Int = 1) -> CGImage {
    let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    return context.makeImage()!
}
