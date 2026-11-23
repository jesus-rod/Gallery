# 03 — In-flight dedup with shared cancellation

Status: ready-for-agent
Blocked by: 02 (protocol only)

`InFlightDedupImageDataLoader(decoratee:)`, an actor keyed by URL with a waiter count per load.

## Acceptance
- Concurrent requests for one URL → one upstream call; every caller gets the data.
- Upstream error reaches every caller.
- Different URLs load independently.
- One of two callers cancels → it gets `CancellationError`, the other still gets the data, upstream not cancelled.
- Every caller cancels → upstream task cancelled.
- After completion the URL is forgotten; a later call goes upstream again.
