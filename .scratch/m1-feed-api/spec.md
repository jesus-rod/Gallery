# M1 — Feed API and paging

Status: done

## Goal

`GalleryCore` can turn Unsplash responses into Photos and Pages, and expose either Stream as an endlessly pageable sequence, fully tested with `swift test`.

## Use cases

**Load a Page of the Editorial feed** (`GET /photos?page=N&per_page=30`)
- Happy: 200 with a JSON array → Photos in API order.
- Sad: 403 with no Request budget left → `rateLimited`. Other non-200 or malformed JSON → `invalidData`. Transport failure → the error propagates from the client.

**Load a Page of Search results** (`GET /search/photos?query=Q&page=N&per_page=30`)
- Happy: 200 with `{ total_pages, results }` → a Page with its Photos and the total page count.
- Sad: as above.

**Page through a Stream**
- First Page loads page 1; loading more loads the next page and accumulates Photos.
- Photos already in the Stream (same id) are dropped from later Pages.
- Search results end after `total_pages`; an empty Page ends either Stream. All stopping rules live in `PhotoStream`; mappers only translate.

## Seams under test

| Seam | Observed through |
|---|---|
| `EditorialPhotosMapper.map(_:from:)`, `SearchPhotosMapper.map(_:from:)` → `PhotoPage` | Return value / thrown error for given `Data` + `HTTPURLResponse` |
| `UnsplashEndpoint.request(baseURL:)` | The built `URLRequest` (URL, query items) |
| `AuthorizingHTTPClient` (decorator over `HTTPClient`) | Requests received by a spy client |
| `URLSessionHTTPClient` | Requests and responses through a `URLProtocol` stub |
| `PhotoStream` → `Paginated<Photo>` | Items and `loadMore` presence, given a stubbed page loader |

## Out of scope

UI, caption rule, image loading, persistence, the request-in-flight guard (lives in the view model, M2).

## Pattern notes

Mappers are public caseless enums with private API models (essential-feed networking). `Paginated<Item>` with an optional `loadMore` closure follows the case-study repo's pagination (*ahead* of the user's course progress).
