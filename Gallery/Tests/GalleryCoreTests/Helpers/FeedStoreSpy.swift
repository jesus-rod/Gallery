import GalleryCore

actor FeedStoreSpy: FeedStore {
    private(set) var saved: [[Photo]] = []
    private let saveError: Error?
    private let stored: [Photo]

    init(saveError: Error? = nil, stored: [Photo] = []) {
        self.saveError = saveError
        self.stored = stored
    }

    func retrieve() async throws -> [Photo] {
        stored
    }

    func save(_ photos: [Photo]) async throws {
        if let saveError { throw saveError }
        saved.append(photos)
    }
}
