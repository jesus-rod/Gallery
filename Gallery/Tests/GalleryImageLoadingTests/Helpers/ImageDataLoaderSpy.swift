import Foundation
import GalleryImageLoading

final class ImageDataLoaderSpy: ImageDataLoader, @unchecked Sendable {
    private struct Pending {
        let index: Int
        let continuation: CheckedContinuation<Data, Error>
    }

    private let lock = NSLock()
    private var _requestedURLs: [URL] = []
    private var _cancelledURLs: [URL] = []
    private var pending: [Pending] = []
    private var requestWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    var requestedURLs: [URL] { lock.withLock { _requestedURLs } }
    var cancelledURLs: [URL] { lock.withLock { _cancelledURLs } }

    func loadImageData(from url: URL) async throws -> Data {
        let index = lock.withLock { () -> Int in
            _requestedURLs.append(url)
            return _requestedURLs.count - 1
        }
        notifyRequestWaiters()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let isCancelled = lock.withLock { () -> Bool in
                    guard !Task.isCancelled else { return true }
                    pending.append(Pending(index: index, continuation: continuation))
                    return false
                }
                if isCancelled {
                    lock.withLock { _cancelledURLs.append(url) }
                    continuation.resume(throwing: CancellationError())
                }
            }
        } onCancel: {
            let cancelled = lock.withLock { () -> Pending? in
                guard let position = pending.firstIndex(where: { $0.index == index }) else { return nil }
                _cancelledURLs.append(url)
                return pending.remove(at: position)
            }
            cancelled?.continuation.resume(throwing: CancellationError())
        }
    }

    func complete(with result: Result<Data, Error>, at index: Int = 0) {
        let completed = lock.withLock { () -> Pending? in
            guard let position = pending.firstIndex(where: { $0.index == index }) else { return nil }
            return pending.remove(at: position)
        }
        completed?.continuation.resume(with: result)
    }

    func untilRequested(count: Int) async {
        await withCheckedContinuation { continuation in
            let isReached = lock.withLock { () -> Bool in
                guard _requestedURLs.count < count else { return true }
                requestWaiters.append((count, continuation))
                return false
            }
            if isReached { continuation.resume() }
        }
    }

    func untilPending(count: Int) async {
        while lock.withLock({ pending.count }) < count {
            await Task.yield()
        }
    }

    private func notifyRequestWaiters() {
        let ready = lock.withLock { () -> [CheckedContinuation<Void, Never>] in
            let count = _requestedURLs.count
            let ready = requestWaiters.filter { $0.count <= count }.map(\.continuation)
            requestWaiters.removeAll { $0.count <= count }
            return ready
        }
        for continuation in ready { continuation.resume() }
    }
}

func eventually(_ condition: () async -> Bool, attempts: Int = 1_000) async {
    for _ in 0..<attempts {
        if await condition() { return }
        await Task.yield()
    }
}
