@MainActor
final class Gate {
    private var isReached = false
    private var isOpen = false
    private var reachedWaiters: [CheckedContinuation<Void, Never>] = []
    private var openWaiters: [CheckedContinuation<Void, Never>] = []

    func pass() async {
        isReached = true
        for waiter in reachedWaiters { waiter.resume() }
        reachedWaiters.removeAll()
        guard !isOpen else { return }
        await withCheckedContinuation { openWaiters.append($0) }
    }

    func untilReached() async {
        guard !isReached else { return }
        await withCheckedContinuation { reachedWaiters.append($0) }
    }

    func open() {
        isOpen = true
        for waiter in openWaiters { waiter.resume() }
        openWaiters.removeAll()
    }
}
