import Foundation

public final class InFlightDedupImageDataLoader: ImageDataLoader, @unchecked Sendable {
    private struct Load {
        let id: UUID
        let task: Task<Void, Never>
        var waiters: [UUID: CheckedContinuation<Data, Error>]
    }

    private let decoratee: ImageDataLoader
    private let lock = NSLock()
    private var loads: [URL: Load] = [:]

    public init(decoratee: ImageDataLoader) {
        self.decoratee = decoratee
    }

    public func loadImageData(from url: URL) async throws -> Data {
        let waiterID = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                register(continuation, as: waiterID, for: url)
            }
        } onCancel: {
            cancelWaiter(waiterID, for: url)
        }
    }

    func waiterCount(for url: URL) -> Int {
        lock.withLock { loads[url]?.waiters.count ?? 0 }
    }

    private func register(_ continuation: CheckedContinuation<Data, Error>, as waiterID: UUID, for url: URL) {
        let isCancelled = lock.withLock { () -> Bool in
            guard !Task.isCancelled else { return true }
            if loads[url] == nil {
                loads[url] = startLoad(for: url)
            }
            loads[url]?.waiters[waiterID] = continuation
            return false
        }
        if isCancelled {
            continuation.resume(throwing: CancellationError())
        }
    }

    private func startLoad(for url: URL) -> Load {
        let loadID = UUID()
        let task = Task { [decoratee, weak self] in
            let result: Result<Data, Error>
            do {
                result = .success(try await decoratee.loadImageData(from: url))
            } catch {
                result = .failure(error)
            }
            self?.complete(loadID, for: url, with: result)
        }
        return Load(id: loadID, task: task, waiters: [:])
    }

    private func complete(_ loadID: UUID, for url: URL, with result: Result<Data, Error>) {
        let waiters = lock.withLock { () -> [CheckedContinuation<Data, Error>] in
            guard let load = loads[url], load.id == loadID else { return [] }
            loads[url] = nil
            return Array(load.waiters.values)
        }
        for waiter in waiters { waiter.resume(with: result) }
    }

    private func cancelWaiter(_ waiterID: UUID, for url: URL) {
        let waiter = lock.withLock { () -> CheckedContinuation<Data, Error>? in
            guard var load = loads[url], let waiter = load.waiters.removeValue(forKey: waiterID) else { return nil }
            if load.waiters.isEmpty {
                load.task.cancel()
                loads[url] = nil
            } else {
                loads[url] = load
            }
            return waiter
        }
        waiter?.resume(throwing: CancellationError())
    }
}
