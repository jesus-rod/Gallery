# In-flight dedup with per-caller cancellation, in a lock-guarded class

The same Rendition is often requested by more than one caller at once: a visible cell and a prefetch, or the same Photo in both Streams. `InFlightDedupImageDataLoader` runs one upstream task per URL and gives every caller its own continuation. If a caller cancels (for example a cell scrolls away and its `.task(id:)` ends), only that caller's continuation is resumed with `CancellationError`. The shared download keeps going for the others, and is cancelled only when the last caller leaves. Once it finishes, the URL is forgotten, so a later request starts fresh and a failure is never cached.

It is a `final class` that guards its state with an `NSLock`, not an actor. A caller has to register its continuation synchronously inside `withCheckedThrowingContinuation`, and a cancellation handler has to be able to remove it synchronously too. An actor-isolated method cannot be called from either closure without an `await`, and that hop opens a window where cancellation is lost. `Mutex` would be neater, but it needs iOS 18 and our minimum is iOS 17.

## Considered Options

- **Actor awaiting a shared `Task.value`**: simple, but awaiting `task.value` does not respond to the caller's cancellation, so a cancelled cell would wait for the whole download anyway.
- **Cancel the shared task whenever any caller cancels**: breaks the visible cell whenever a prefetch for the same URL is cancelled.
- **No dedup, rely on the disk cache**: concurrent misses would download the same bytes twice.

## Consequences

- The class is `@unchecked Sendable`, so its thread safety rests on the lock, not the compiler. Every state change happens inside `lock.withLock`, and continuations are resumed outside the lock.
- Dedup sits below the disk cache, so two concurrent misses both read the disk once before collapsing into one download.
- The shared task holds the loader weakly. A caller keeps the loader alive while it is awaiting.
