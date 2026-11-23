import Foundation

public protocol ImageDataStore: Sendable {
    func retrieve(for url: URL) async throws -> Data?
    func insert(_ data: Data, for url: URL) async throws
}
