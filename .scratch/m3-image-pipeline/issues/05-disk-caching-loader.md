# 05 — Disk-caching image data loader

Status: ready-for-agent
Blocked by: 04 (protocol only)

`DiskCachingImageDataLoader(decoratee:store:)`.

## Acceptance
- Store hit → data, decoratee not called.
- Miss → decoratee data returned and inserted.
- Store retrieve error → treated as miss. Insert error → ignored, data still returned.
- Decoratee error → rethrown, nothing inserted.
