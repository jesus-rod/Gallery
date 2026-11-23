import Foundation
import GalleryImageLoading
import Testing

@Suite(.trackingLeaks)
struct DownsamplingImageLoaderTests {
    @Test func load_requestsDataForGivenURL() async throws {
        let (sut, loader) = makeSUT(result: .success(pngData(width: 10, height: 10)))

        _ = try await sut.loadImage(from: anyURL, maxPixelSize: 10)

        #expect(loader.requestedURLs == [anyURL])
    }

    @Test func load_downsamplesLongestSideToMaxPixelSize() async throws {
        let (sut, _) = makeSUT(result: .success(pngData(width: 400, height: 200)))

        let image = try await sut.loadImage(from: anyURL, maxPixelSize: 100)

        #expect(image.width == 100)
        #expect(image.height == 50)
    }

    @Test func load_neverUpscalesSmallerImages() async throws {
        let (sut, _) = makeSUT(result: .success(pngData(width: 40, height: 20)))

        let image = try await sut.loadImage(from: anyURL, maxPixelSize: 100)

        #expect(image.width == 40)
        #expect(image.height == 20)
    }

    @Test func load_throwsInvalidImageDataOnUndecodableData() async {
        let (sut, _) = makeSUT(result: .success(Data("not an image".utf8)))

        await #expect(throws: DownsamplingImageLoader.Error.invalidImageData) {
            try await sut.loadImage(from: anyURL, maxPixelSize: 100)
        }
    }

    @Test func load_rethrowsDataLoaderError() async {
        let (sut, _) = makeSUT(result: .failure(AnyError()))

        await #expect(throws: AnyError.self) {
            try await sut.loadImage(from: anyURL, maxPixelSize: 100)
        }
    }

    private func makeSUT(result: Result<Data, Error>, sourceLocation: SourceLocation = #_sourceLocation) -> (
        DownsamplingImageLoader, ImageDataLoaderStub
    ) {
        let loader = ImageDataLoaderStub(result: result)
        let sut = DownsamplingImageLoader(dataLoader: loader)
        trackForMemoryLeaks(loader, sourceLocation: sourceLocation)
        return (sut, loader)
    }
}
