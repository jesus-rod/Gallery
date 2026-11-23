import CryptoKit
import Foundation

public actor FileImageDataStore: ImageDataStore {
    private let directory: URL
    private let currentDate: @Sendable () -> Date
    private let fileManager = FileManager()

    public init(directory: URL, currentDate: @escaping @Sendable () -> Date = { Date() }) {
        self.directory = directory
        self.currentDate = currentDate
    }

    public func retrieve(for url: URL) throws -> Data? {
        let file = fileURL(for: url)
        guard fileManager.fileExists(atPath: file.path()) else { return nil }
        let data = try Data(contentsOf: file)
        try? markUsed(file)
        return data
    }

    public func insert(_ data: Data, for url: URL) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = fileURL(for: url)
        try data.write(to: file, options: .atomic)
        try markUsed(file)
    }

    public func evict(toFit byteLimit: Int) throws {
        guard fileManager.fileExists(atPath: directory.path()) else { return }
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        let entries = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys)
            .map { file in
                let values = try file.resourceValues(forKeys: Set(keys))
                return (
                    file: file, size: values.fileSize ?? 0, lastUsed: values.contentModificationDate ?? .distantPast
                )
            }
            .sorted { $0.lastUsed < $1.lastUsed }

        var total = entries.reduce(0) { $0 + $1.size }
        for entry in entries where total > byteLimit {
            try fileManager.removeItem(at: entry.file)
            total -= entry.size
        }
    }

    private func markUsed(_ file: URL) throws {
        try fileManager.setAttributes([.modificationDate: currentDate()], ofItemAtPath: file.path())
    }

    private func fileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: name)
    }
}
