# 01 — Caption rule

Status: done

A pure function in `GalleryUI` returning a Photo's Caption: alt description, else description, else localized "Untitled photo" (String Catalog).

## Acceptance
- Alt description wins when present.
- Falls back to description, then to the placeholder.
- Empty or whitespace-only strings count as missing.
