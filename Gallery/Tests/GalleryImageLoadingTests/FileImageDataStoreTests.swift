import Foundation
import GalleryImageLoading
import Testing

@Suite(.trackingLeaks)
final class FileImageDataStoreTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "FileImageDataStoreTests-\(UUID().uuidString)")
    private let urlA = URL(string: "https://images.example.com/a?w=100")!
    private let urlB = URL(string: "https://images.example.com/b?w=100")!
    private let urlC = URL(string: "https://images.example.com/c?w=100")!

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func retrieve_deliversNilOnEmptyStore() async throws {
        let sut = makeSUT()

        #expect(try await sut.retrieve(for: urlA) == nil)
    }

    @Test func retrieve_deliversInsertedData() async throws {
        let sut = makeSUT()
        let data = Data("a".utf8)

        try await sut.insert(data, for: urlA)

        #expect(try await sut.retrieve(for: urlA) == data)
        #expect(try await sut.retrieve(for: urlB) == nil)
    }

    @Test func insert_overridesPreviousData() async throws {
        let sut = makeSUT()

        try await sut.insert(Data("first".utf8), for: urlA)
        try await sut.insert(Data("last".utf8), for: urlA)

        #expect(try await sut.retrieve(for: urlA) == Data("last".utf8))
    }

    @Test func insert_persistsAcrossInstancesOnTheSameDirectory() async throws {
        try await makeSUT().insert(Data("a".utf8), for: urlA)

        #expect(try await makeSUT().retrieve(for: urlA) == Data("a".utf8))
    }

    @Test func storesOnSeparateDirectories_doNotInterfere() async throws {
        let other = FileManager.default.temporaryDirectory.appending(
            path: "FileImageDataStoreTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: other) }

        try await makeSUT().insert(Data("a".utf8), for: urlA)

        #expect(try await FileImageDataStore(directory: other).retrieve(for: urlA) == nil)
    }

    @Test func retrieve_returnsTheDataWhenUpdatingTheLastUsedDateFails() async throws {
        let sut = makeSUT()
        try await sut.insert(tenBytes, for: urlA)
        let file = try #require(
            try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).first)
        try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: file.path())
        defer { try? FileManager.default.setAttributes([.immutable: false], ofItemAtPath: file.path()) }

        #expect(try await sut.retrieve(for: urlA) == tenBytes)
    }

    @Test func evict_doesNothingWhenUnderBudget() async throws {
        let sut = makeSUT()
        try await sut.insert(tenBytes, for: urlA)
        try await sut.insert(tenBytes, for: urlB)

        try await sut.evict(toFit: 20)

        #expect(try await sut.retrieve(for: urlA) == tenBytes)
        #expect(try await sut.retrieve(for: urlB) == tenBytes)
    }

    @Test func evict_removesLeastRecentlyInsertedEntriesUntilWithinBudget() async throws {
        let clock = Clock()
        let sut = makeSUT(clock: clock)
        try await sut.insert(tenBytes, for: urlA)
        clock.advance()
        try await sut.insert(tenBytes, for: urlB)
        clock.advance()
        try await sut.insert(tenBytes, for: urlC)

        try await sut.evict(toFit: 15)

        #expect(try await sut.retrieve(for: urlA) == nil)
        #expect(try await sut.retrieve(for: urlB) == nil)
        #expect(try await sut.retrieve(for: urlC) == tenBytes)
    }

    @Test func retrieve_marksEntryAsRecentlyUsed() async throws {
        let clock = Clock()
        let sut = makeSUT(clock: clock)
        try await sut.insert(tenBytes, for: urlA)
        clock.advance()
        try await sut.insert(tenBytes, for: urlB)
        clock.advance()
        _ = try await sut.retrieve(for: urlA)

        try await sut.evict(toFit: 10)

        #expect(try await sut.retrieve(for: urlB) == nil)
        #expect(try await sut.retrieve(for: urlA) == tenBytes)
    }

    private var tenBytes: Data { Data(repeating: 1, count: 10) }

    private func makeSUT(clock: Clock = Clock(), sourceLocation: SourceLocation = #_sourceLocation)
        -> FileImageDataStore
    {
        let sut = FileImageDataStore(directory: directory, currentDate: clock.now)
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        return sut
    }
}

private final class Clock: @unchecked Sendable {
    private let lock = NSLock()
    private var date = Date(timeIntervalSince1970: 1_000_000)

    @Sendable func now() -> Date { lock.withLock { date } }

    func advance() { lock.withLock { date += 60 } }
}
