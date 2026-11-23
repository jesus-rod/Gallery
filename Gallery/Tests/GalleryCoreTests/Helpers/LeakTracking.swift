import Foundation
import Testing

struct LeakTrackingTrait: TestTrait, SuiteTrait, TestScoping {
    var isRecursive: Bool { true }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        let tracker = LeakTracker()
        try await LeakTracker.$current.withValue(tracker) {
            try await function()
        }
        tracker.verify()
    }
}

extension Trait where Self == LeakTrackingTrait {
    static var trackingLeaks: Self { LeakTrackingTrait() }
}

final class LeakTracker: @unchecked Sendable {
    @TaskLocal static var current: LeakTracker?

    private struct Entry {
        weak var instance: AnyObject?
        let sourceLocation: SourceLocation
    }

    private let lock = NSLock()
    private var entries: [Entry] = []

    func track(_ instance: AnyObject, sourceLocation: SourceLocation) {
        lock.withLock { entries.append(Entry(instance: instance, sourceLocation: sourceLocation)) }
    }

    fileprivate func verify() {
        let leaked = lock.withLock { entries.filter { $0.instance != nil } }
        for entry in leaked {
            Issue.record(
                "Instance should have been deallocated. Potential memory leak.",
                sourceLocation: entry.sourceLocation
            )
        }
    }
}

func trackForMemoryLeaks(_ instance: AnyObject, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let tracker = LeakTracker.current else {
        Issue.record("trackForMemoryLeaks needs the .trackingLeaks trait.", sourceLocation: sourceLocation)
        return
    }
    tracker.track(instance, sourceLocation: sourceLocation)
}
