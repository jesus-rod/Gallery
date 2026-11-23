# 02 — Remote image data loader

Status: done

`RemoteImageDataLoader(fetch:)` in `GalleryImageLoading`; the fetch closure returns `(Data, HTTPURLResponse)`.

## Acceptance
- Requests the given URL.
- 200 with non-empty data → data.
- Non-200 → `invalidData`; 200 with empty data → `invalidData`.
- Fetch error is rethrown (connectivity stays recognisable).
- No leak.
