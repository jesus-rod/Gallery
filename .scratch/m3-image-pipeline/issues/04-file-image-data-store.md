# 04 — File image data store

Status: ready-for-agent

`FileImageDataStore(directory:)` storing raw bytes in a directory (Caches in the app), file name derived from the URL (SHA-256 via CryptoKit, or a stable hash).

## Acceptance
- Empty store → nil.
- Insert then retrieve → same data; insert twice → last value wins.
- Retrieve marks the entry as recently used (modification date touched).
- `evict(toFit: bytes)` removes least-recently-used files until the total is at or under the budget; no-op under budget.
- Operations off the main actor; separate instances on separate directories do not interfere.
