# Offline feed: JSON file store, network first, no expiry

The Offline feed holds up to about 300 of the most recently loaded Editorial feed Photos as a versioned Codable JSON file behind a `FeedStore` protocol, with storage models separate from the domain. Loading tries the network first and falls back to the Offline feed only on failure. Unlike the 7-day cache policy in the Essential Feed course, the Offline feed never expires: it is shown only when the alternative is an empty screen, and the UI labels it as offline and possibly out of date. A successful first Page replaces it. Search results are never stored.

## Considered Options

- **SwiftData / Core Data**: would tie storage models to a framework and add migration concerns, for a few hundred small records read and written as a whole.
- **Cache-first with background refresh**: would save a request at launch, but would show stale content even when online.
