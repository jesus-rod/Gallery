# Full screen pages through the Stream, not a single Photo

Opening a Photo used to show that one Photo. Now full screen shows the Stream it came from (the Editorial feed or the current Search results) and the user swipes left and right between its Photos, as in any photo viewer. The route carries the Stream id and the starting Photo; the full-screen view reads that Stream's Photos from `GalleryViewModel.photos(in:)` on every render, so Pages loaded while paging appear without reopening. Reaching a Photo near the end calls `photoAppeared(_:in:)`, the same load-more path the grid uses, so the one-request-in-flight rule and every stopping rule stay in `StreamPager` and `PhotoStream`.

The pager is a horizontal `ScrollView` with `.scrollTargetBehavior(.paging)`, a `LazyHStack` of pages and `.scrollPosition(id:)`, all available on iOS 17. Each page owns its zoom state, so zoom resets when a page leaves, and paging is disabled while the current page is zoomed so drags pan instead. Parallax reads each page's frame with `.visualEffect`, which writes no state per frame. Only the current page and its neighbours request the full-screen Rendition; the rest show the cached grid image or the Preview, so memory stays flat however far the user swipes.

## Considered Options

- **Keep one Photo per push**: simplest, but swiping is the first thing people try in a full-screen photo, and the brief grades the transition and the feel.
- **`TabView` with `.page` style**: pages for free, but it builds pages eagerly on some versions, its scroll position can't be read for parallax without a `GeometryReader` per page, and it fights the zoom and dismiss gestures.
- **Copy the Photos into the route**: a frozen array would miss Pages loaded while paging and would duplicate the Stream's state.

## Consequences

- The zoom-back target follows the current Photo: the root keeps the current Photo id, the destination's zoom source id is built from it, and the grid scrolls that cell into view before the pop so the zoom lands on a visible cell.
- The drag gesture on each page has to share the screen with the horizontal scroll: it only starts a dismiss or Info swipe when the drag is mostly vertical.
- The route is still `Hashable`, but its identity is the starting Photo, not the one on screen when the user goes back.
