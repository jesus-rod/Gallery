import Foundation
import GalleryCore
import Testing

@Suite(.trackingLeaks)
final class CodableFeedStoreTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "CodableFeedStoreTests-\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func retrieve_deliversNothingWhenNoFileExists() async throws {
        let sut = makeSUT()

        #expect(try await sut.retrieve() == [])
    }

    @Test func retrieve_deliversWhatWasSaved() async throws {
        let sut = makeSUT()
        let photos = [makeFullPhoto(id: "1"), makeSparsePhoto(id: "2")]

        try await sut.save(photos)

        #expect(try await sut.retrieve() == photos)
    }

    @Test func save_replacesWhatWasSavedBefore() async throws {
        let sut = makeSUT()
        let last = [makeFullPhoto(id: "3")]

        try await sut.save([makeFullPhoto(id: "1"), makeSparsePhoto(id: "2")])
        try await sut.save(last)

        #expect(try await sut.retrieve() == last)
    }

    @Test func retrieve_hasNoSideEffects() async throws {
        let sut = makeSUT()
        let photos = [makeFullPhoto(id: "1")]
        try await sut.save(photos)

        #expect(try await sut.retrieve() == photos)
        #expect(try await sut.retrieve() == photos)
    }

    @Test func retrieve_deliversNothingForAnUnknownVersion() async throws {
        let sut = makeSUT()
        try await sut.save([makeFullPhoto(id: "1")])
        let saved = try String(contentsOf: fileURL, encoding: .utf8)
        try writeFile(Data(saved.replacing(#""version":1"#, with: #""version":2"#).utf8))

        #expect(try await sut.retrieve() == [])
    }

    @Test func retrieve_failsOnCorruptData() async throws {
        let sut = makeSUT()
        try writeFile(Data("not json".utf8))

        await #expect(throws: (any Error).self) { try await sut.retrieve() }
    }

    @Test func save_failsWhenTheLocationCannotBeWritten() async throws {
        let blocker = directory.appending(path: "blocker")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data().write(to: blocker)
        let sut = makeSUT(fileURL: blocker.appending(path: "feed.json"))

        await #expect(throws: (any Error).self) { try await sut.save([makeFullPhoto(id: "1")]) }
    }

    @Test func save_createsAMissingParentDirectory() async throws {
        let nested = directory.appending(path: "a/b/feed.json")
        let sut = makeSUT(fileURL: nested)

        try await sut.save([makeFullPhoto(id: "1")])

        #expect(try await sut.retrieve() == [makeFullPhoto(id: "1")])
    }

    private func writeFile(_ data: Data) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL)
    }

    private func makeFullPhoto(id: String) -> Photo {
        makePhoto(id: id, blurHash: "LEHV6nWB2yk8", description: "A description", altDescription: "An alt").model
    }

    private func makeSparsePhoto(id: String) -> Photo {
        makePhoto(id: id).model
    }

    private var fileURL: URL { directory.appending(path: "feed.json") }

    private func makeSUT(fileURL: URL? = nil) -> CodableFeedStore {
        let sut = CodableFeedStore(fileURL: fileURL ?? self.fileURL)
        trackForMemoryLeaks(sut)
        return sut
    }
}
