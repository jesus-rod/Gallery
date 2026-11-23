import Foundation

public final class ImagePrefetcher: @unchecked Sendable {
    public struct Request: Hashable, Sendable {
        public let url: URL
        public let maxPixelSize: Int

        public init(url: URL, maxPixelSize: Int) {
            self.url = url
            self.maxPixelSize = maxPixelSize
        }
    }

    private struct Load {
        let id: UUID
        let task: Task<Void, Never>
    }

    private let loader: ImageLoader
    private let lock = NSLock()
    private var loads: [Request: Load] = [:]

    public init(loader: ImageLoader) {
        self.loader = loader
    }

    deinit {
        for load in loads.values { load.task.cancel() }
    }

    public func prefetch(_ requests: [Request]) {
        let window = Set(requests)
        let dropped = lock.withLock { () -> [Load] in
            let dropped = loads.filter { !window.contains($0.key) }
            for request in dropped.keys { loads[request] = nil }
            for request in window where loads[request] == nil {
                loads[request] = start(request)
            }
            return Array(dropped.values)
        }
        for load in dropped { load.task.cancel() }
    }

    var inFlightCount: Int {
        lock.withLock { loads.count }
    }

    private func start(_ request: Request) -> Load {
        let id = UUID()
        let task = Task { [loader, weak self] in
            _ = try? await loader.loadImage(from: request.url, maxPixelSize: request.maxPixelSize)
            self?.finish(request, id: id)
        }
        return Load(id: id, task: task)
    }

    private func finish(_ request: Request, id: UUID) {
        lock.withLock {
            if loads[request]?.id == id {
                loads[request] = nil
            }
        }
    }
}
