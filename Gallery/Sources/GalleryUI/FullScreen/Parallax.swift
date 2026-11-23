import CoreGraphics

enum Parallax {
    static func offset(pageMinX: CGFloat, pageWidth: CGFloat, factor: CGFloat) -> CGFloat {
        guard pageWidth > 0 else { return 0 }
        let pages = min(max(pageMinX / pageWidth, -1), 1)
        return -pages * factor * pageWidth
    }
}
