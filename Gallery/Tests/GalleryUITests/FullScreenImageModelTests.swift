import CoreGraphics
import Foundation
import GalleryCore
import Testing

@testable import GalleryUI

@MainActor
@Suite(.trackingLeaks)
struct FullScreenImageModelTests {
    private let gridSize = ImageSize(points: 100, scale: 2)
    private let fitting = FittingSize(width: 400, height: 800, scale: 3)
    private let otherFitting = FittingSize(width: 800, height: 400, scale: 3)

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
        #expect(sut.state == .preview)
    }

    @Test func load_requestsTheGridImageAtTheGridSizeAndTheFullImageAtTheFittingSize() async {
        let (sut, images) = makeSUT(photo: makePhoto(id: "a"))

        await sut.load(fitting: fitting)

        #expect(images.requests == [PhotoImagesSpy.Request(photoID: "a", size: gridSize)])
        #expect(images.fullScreenRequests == [PhotoImagesSpy.FullScreenRequest(photoID: "a", size: fitting)])
    }

    @Test func load_showsTheGridImageWhileTheFullImageIsLoading() async {
        let grid = makeImage()
        let fullGate = Gate()
        let (sut, images) = makeSUT()
        images.stub(.success(grid))
        images.stubFullScreen(.success(makeImage(width: 2)), gate: fullGate)

        let task = Task { await sut.load(fitting: fitting) }
        await untilState(.gridImage(grid), of: sut)

        #expect(sut.state == .gridImage(grid))
        fullGate.open()
        await task.value
    }

    @Test func load_showsTheFullImage() async {
        let full = makeImage(width: 2)
        let (sut, images) = makeSUT()
        images.stub(.success(makeImage()))
        images.stubFullScreen(.success(full))

        await sut.load(fitting: fitting)

        #expect(sut.state == .fullImage(full))
    }

    @Test func load_keepsTheFullImageWhenTheGridImageArrivesLater() async {
        let full = makeImage(width: 2)
        let gridGate = Gate()
        let (sut, images) = makeSUT()
        images.stub(.success(makeImage()), gate: gridGate)
        images.stubFullScreen(.success(full))

        let task = Task { await sut.load(fitting: fitting) }
        await untilState(.fullImage(full), of: sut)
        gridGate.open()
        await task.value

        #expect(sut.state == .fullImage(full))
    }

    @Test func load_keepsTheGridImageWhenTheFullImageFails() async {
        let grid = makeImage()
        let (sut, images) = makeSUT()
        images.stub(.success(grid))
        images.stubFullScreen(.failure(AnyError()))

        await sut.load(fitting: fitting)

        #expect(sut.state == .gridImage(grid))
    }

    @Test func load_keepsThePreviewWhenBothFail() async {
        let preview = makeImage()
        let (sut, images) = makeSUT(preview: preview)
        images.stub(.failure(AnyError()))
        images.stubFullScreen(.failure(AnyError()))

        await sut.load(fitting: fitting)

        #expect(sut.state == .preview)
        #expect(sut.preview == preview)
    }

    @Test func load_requestsOnlyTheFullImageOnceItIsShown() async {
        let (sut, images) = makeSUT()
        images.stub(.success(makeImage()))
        images.stubFullScreen(.success(makeImage(width: 2)))
        await sut.load(fitting: fitting)

        await sut.load(fitting: otherFitting)

        #expect(images.requests.count == 1)
        #expect(images.fullScreenRequests.count == 2)
    }

    @Test func load_keepsTheShownFullImageWhenANewSizeFails() async {
        let full = makeImage(width: 2)
        let (sut, images) = makeSUT()
        images.stubFullScreen(.success(full))
        await sut.load(fitting: fitting)

        images.stubFullScreen(.failure(AnyError()))
        await sut.load(fitting: otherFitting)

        #expect(sut.state == .fullImage(full))
    }

    @Test func load_replacesTheFullImageWithTheOneForTheNewSize() async {
        let newFull = makeImage(width: 3)
        let (sut, images) = makeSUT()
        images.stubFullScreen(.success(makeImage(width: 2)))
        await sut.load(fitting: fitting)

        images.stubFullScreen(.success(newFull))
        await sut.load(fitting: otherFitting)

        #expect(sut.state == .fullImage(newFull))
    }

    @Test func isFullImageShown_isTrueOnlyForTheFullImage() async {
        let grid = makeImage()
        let (sut, images) = makeSUT()
        #expect(sut.isFullImageShown == false)

        images.stub(.success(grid))
        images.stubFullScreen(.failure(AnyError()))
        await sut.load(fitting: fitting)
        #expect(sut.isFullImageShown == false)

        images.stubFullScreen(.success(makeImage(width: 2)))
        await sut.load(fitting: fitting)
        #expect(sut.isFullImageShown == true)
    }

    private func untilState(_ expected: FullScreenImageModel.State, of sut: FullScreenImageModel) async {
        for _ in 0..<500 where sut.state != expected {
            await Task.yield()
        }
    }

    private func makeSUT(
        photo: Photo = makePhoto(),
        preview: CGImage? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (FullScreenImageModel, PhotoImagesSpy) {
        let spy = PhotoImagesSpy(preview: preview)
        let sut = FullScreenImageModel(photo: photo, images: spy.images, gridSize: gridSize)
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        trackForMemoryLeaks(spy, sourceLocation: sourceLocation)
        return (sut, spy)
    }
}
