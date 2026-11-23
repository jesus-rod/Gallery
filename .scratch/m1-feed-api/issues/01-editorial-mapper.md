# 01 — Photo and Editorial feed mapper

Status: done

Introduce `Photo` (id, width, height, blurHash, description, altDescription, renditions raw/small/regular, Photographer name + profile URL), `PhotoPage` (photos, totalPages) and `EditorialPhotosMapper` mapping a 200 JSON array into a `PhotoPage` with no total pages.

## Acceptance
- Non-200 and malformed JSON throw `invalidData`.
- 200 with an empty array maps to an empty Page; with items, maps every field, nil for missing optional ones.
