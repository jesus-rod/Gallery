import Foundation
import GalleryCore
import Testing

struct PhotoStreamTests {
    @Test func firstPage_loadsPage1AndDeliversItsPhotos() async throws {
        let photos = [makePhoto(id: "1").model, makePhoto(id: "2").model]
        let loader = PageLoaderStub(pages: [1: .success(PhotoPage(photos: photos, totalPages: nil))])

        let paginated = try await makeSUT(loader).firstPage()

        #expect(await loader.requestedPages == [1])
        #expect(paginated.items == photos)
    }

    @Test func loadMore_loadsTheNextPageAndAccumulatesPhotos() async throws {
        let page1 = [makePhoto(id: "1").model, makePhoto(id: "2").model]
        let page2 = [makePhoto(id: "3").model]
        let loader = PageLoaderStub(pages: [
            1: .success(PhotoPage(photos: page1, totalPages: nil)),
            2: .success(PhotoPage(photos: page2, totalPages: nil)),
        ])

        let first = try await makeSUT(loader).firstPage()
        let loadMore = try #require(first.loadMore)
        let second = try await loadMore()

        #expect(await loader.requestedPages == [1, 2])
        #expect(second.items == page1 + page2)
    }

    @Test func loadMore_dropsPhotosAlreadyInTheStream() async throws {
        let photo1 = makePhoto(id: "1").model
        let photo2 = makePhoto(id: "2").model
        let photo3 = makePhoto(id: "3").model
        let loader = PageLoaderStub(pages: [
            1: .success(PhotoPage(photos: [photo1, photo2], totalPages: nil)),
            2: .success(PhotoPage(photos: [photo2, photo3, photo3], totalPages: nil)),
        ])

        let first = try await makeSUT(loader).firstPage()
        let loadMore = try #require(first.loadMore)
        let second = try await loadMore()

        #expect(second.items == [photo1, photo2, photo3])
    }

    @Test func loadMore_isNilWhenThePageReachesTotalPages() async throws {
        let loader = PageLoaderStub(pages: [
            1: .success(PhotoPage(photos: [makePhoto(id: "1").model], totalPages: 2)),
            2: .success(PhotoPage(photos: [makePhoto(id: "2").model], totalPages: 2)),
        ])

        let first = try await makeSUT(loader).firstPage()
        let loadMore = try #require(first.loadMore)
        let last = try await loadMore()

        #expect(last.loadMore == nil)
    }

    @Test(arguments: [nil, 5])
    func loadMore_isNilWhenAPageComesBackEmpty(totalPages: Int?) async throws {
        let loader = PageLoaderStub(pages: [1: .success(PhotoPage(photos: [], totalPages: totalPages))])

        let first = try await makeSUT(loader).firstPage()

        #expect(first.items.isEmpty)
        #expect(first.loadMore == nil)
    }

    @Test func loadMore_retriesTheSamePageAfterAFailure() async throws {
        let page1 = [makePhoto(id: "1").model]
        let page2 = [makePhoto(id: "2").model]
        let loader = PageLoaderStub(pages: [
            1: .success(PhotoPage(photos: page1, totalPages: nil)),
            2: .failure(URLError(.notConnectedToInternet)),
        ])
        let first = try await makeSUT(loader).firstPage()
        let loadMore = try #require(first.loadMore)
        await #expect(throws: URLError.self) { try await loadMore() }

        await loader.stub(page: 2, with: .success(PhotoPage(photos: page2, totalPages: nil)))
        let second = try await loadMore()

        #expect(await loader.requestedPages == [1, 2, 2])
        #expect(second.items == page1 + page2)
    }

    private func makeSUT(_ loader: PageLoaderStub) -> PhotoStream {
        PhotoStream(loadPage: { try await loader.load($0) })
    }
}

actor PageLoaderStub {
    private(set) var requestedPages: [Int] = []
    private var pages: [Int: Result<PhotoPage, Error>]

    init(pages: [Int: Result<PhotoPage, Error>]) {
        self.pages = pages
    }

    func stub(page: Int, with result: Result<PhotoPage, Error>) {
        pages[page] = result
    }

    func load(_ page: Int) throws -> PhotoPage {
        requestedPages.append(page)
        guard let result = pages[page] else {
            Issue.record("Unexpected request for page \(page)")
            throw URLError(.unknown)
        }
        return try result.get()
    }
}
