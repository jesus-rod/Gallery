import CoreGraphics
import Foundation
import GalleryCore
import Testing

@testable import GalleryUI

@MainActor
@Suite(.trackingLeaks)
struct PhotoImageModelTests {
    private let size = ImageSize(points: 100, scale: 2)

    @Test func init_showsThePhotosPreview() {
        let preview = makeImage()
        let (sut, _) = makeSUT(preview: preview)

        #expect(sut.state == .preview(preview))
    }

    @Test func init_showsNoPreviewWhenThereIsNone() {
        let (sut, _) = makeSUT(preview: nil)

        #expect(sut.state == .preview(nil))
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

        #expect(sut.state == .image(image))
    }

    @Test func load_keepsThePreviewOnFailure() async {
        let preview = makeImage()
        let (sut, images) = makeSUT(preview: preview)
        images.stub(.failure(AnyError()))

        await sut.load(size: size)

        #expect(sut.state == .preview(preview))
    }

    @Test func load_keepsTheLoadedImageWhenALaterLoadFails() async {
        let image = makeImage()
        let (sut, images) = makeSUT()
        images.stub(.success(image))
        await sut.load(size: size)

        images.stub(.failure(AnyError()))
        await sut.load(size: ImageSize(points: 200, scale: 2))

        #expect(sut.state == .image(image))
    }

    @Test func isLoaded_isTrueOnlyOnceTheImageIsShown() async {
        let (sut, images) = makeSUT(preview: makeImage())
        #expect(sut.isLoaded == false)

        images.stub(.success(makeImage()))
        await sut.load(size: size)

        #expect(sut.isLoaded == true)
    }

    private func makeSUT(
        photo: Photo = makePhoto(),
        preview: CGImage? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (PhotoImageModel, PhotoImagesSpy) {
        let spy = PhotoImagesSpy(preview: preview)
        let sut = PhotoImageModel(photo: photo, images: spy.images)
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

    struct Prefetch: Equatable {
        let photoIDs: [String]
        let size: ImageSize
    }

    private let lock = NSLock()
    private let preview: CGImage?
    private var result: Result<CGImage, Error> = .failure(AnyError())
    private var _requests: [Request] = []
    private var _prefetches: [Prefetch] = []

    var requests: [Request] { lock.withLock { _requests } }
    var prefetches: [Prefetch] { lock.withLock { _prefetches } }

    init(preview: CGImage? = nil) {
        self.preview = preview
    }

    func stub(_ result: Result<CGImage, Error>) {
        lock.withLock { self.result = result }
    }

    var images: PhotoImages {
        PhotoImages(
            preview: { [preview] _ in preview },
            image: { [self] photo, size in
                try lock.withLock {
                    _requests.append(Request(photoID: photo.id, size: size))
                    return try result.get()
                }
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
