# Fixed-size square cells in a SwiftUI `LazyVGrid`

The grid uses square, center-cropped cells in a `LazyVGrid` with adaptive columns (two on compact widths, three on regular). Fixed cell sizes make layout trivial during fast scrolling and let us request a Rendition at exactly the cell's pixel size. A masonry layout that keeps each Photo's aspect ratio would look richer, but SwiftUI has no lazy masonry container. Building one, or wrapping `UICollectionView` (which the brief asks us to justify), costs time and adds layout risk that would be hard to undo later.
