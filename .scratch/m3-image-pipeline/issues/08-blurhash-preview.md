# 08 — BlurHash Preview

Status: ready-for-agent

Own decoder `BlurHash.decode(_:width:height:) -> CGImage?` (base83, sRGB ↔ linear, DCT sum) and `PreviewCache` caching decoded Previews by hash at `previewSize`.

## Acceptance
- Valid hash → image of the requested size.
- Invalid length or characters → nil.
- A one-component hash decodes to its DC colour (checked within tolerance).
- `PreviewCache` decodes a given hash once.
