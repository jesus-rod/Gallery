# 02 — Search results mapper

Status: ready-for-agent
Blocked by: 01

`SearchPhotosMapper` maps `{ total_pages, results }` into a `PhotoPage` carrying `total_pages`. No paging decisions in the mapper.

## Acceptance
- Same error rules as 01; shares the photo DTO mapping with it.
