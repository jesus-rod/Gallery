# Gallery

An iOS gallery for browsing Unsplash photos: an endless grid of the Editorial feed, search, and a full-screen view of a single photo.

## Photos

**Photo**:
A single Unsplash image together with its descriptive metadata and its Photographer.
_Avoid_: Image (reserved for the pixels), item, picture, post

**Photographer**:
The Unsplash user credited as the author of a Photo.
_Avoid_: User, author, owner

**Caption**:
The short text shown with a Photo: its alt description, else its description, else a generic placeholder.
_Avoid_: Title, label, description (that is one of the Caption's sources)

**Rendition**:
A version of a Photo's image at a specific size, served by the Unsplash CDN.
_Avoid_: Thumbnail, variant, size, URL

**Preview**:
A blurred, low-detail stand-in for a Photo, derived from its BlurHash and shown before any Rendition arrives.
_Avoid_: Placeholder (reserved for missing content), skeleton, blur

## Browsing

**Stream**:
An endless, page-by-page sequence of Photos shown in the grid. There are two kinds: the Editorial feed and Search results.
_Avoid_: Feed (when meaning either kind), list, collection (an Unsplash concept we do not use)

**Editorial feed**:
The Stream of photos Unsplash curates for its home page; what the app shows by default.
_Avoid_: Home, main feed, timeline

**Search results**:
The Stream of Photos matching a Query. Unlike the Editorial feed, it has an end.
_Avoid_: Search feed, results list

**Query**:
The text a person submits to search for Photos.
_Avoid_: Search term, keyword, filter

**Page**:
One batch of Photos returned by a single request for a Stream.
_Avoid_: Chunk, batch, slice

**Full-screen view**:
A single Photo shown at full size, opened from the grid and dismissed back to it.
_Avoid_: Detail, preview (see Preview), lightbox

## Availability

**Request budget**:
The number of API requests Unsplash still allows in the current hour. Image downloads from the CDN do not consume it.
_Avoid_: Quota, rate limit (that is the event of exhausting it)

**Offline feed**:
The most recently loaded Photos of the Editorial feed, kept on the device so they can be shown when the network is unavailable.
_Avoid_: Cache (too generic), snapshot, saved feed

**Load failure**:
Why a Page could not be loaded, in the user's terms: offline, Request budget exhausted, access key rejected, or anything else. Each screen chooses its own wording for it.
_Avoid_: Network error (most failures are not about the network), API error
