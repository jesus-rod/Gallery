import CoreGraphics

struct ZoomTransform: Equatable {
    static let maximumScale = 4.0
    static let doubleTapScale = 2.5
    static let dismissDistance = 120.0
    static let dismissFlickDistance = 300.0
    static let infoDistance = 80.0
    static let infoFlickDistance = 200.0

    private(set) var scale = 1.0
    private(set) var offset = CGSize.zero

    var isZoomed: Bool { scale > 1 }

    init() {}

    private init(scale: Double, offset: CGSize) {
        self.scale = scale
        self.offset = offset
    }

    func magnified(by magnification: Double, anchor: CGPoint, container: CGSize, content: CGSize) -> ZoomTransform {
        let newScale = min(max(scale * magnification, 1), Self.maximumScale)
        let ratio = CGFloat(newScale / scale)
        let relative = Self.relativeToCentre(anchor, in: container)
        let proposed = CGSize(
            width: relative.width - (relative.width - offset.width) * ratio,
            height: relative.height - (relative.height - offset.height) * ratio
        )
        return ZoomTransform(
            scale: newScale,
            offset: Self.clamped(proposed, scale: newScale, container: container, content: content)
        )
    }

    func toggled(at point: CGPoint, container: CGSize, content: CGSize) -> ZoomTransform {
        if isZoomed { return ZoomTransform() }
        let relative = Self.relativeToCentre(point, in: container)
        let factor = CGFloat(Self.doubleTapScale - 1)
        let proposed = CGSize(width: -relative.width * factor, height: -relative.height * factor)
        return ZoomTransform(
            scale: Self.doubleTapScale,
            offset: Self.clamped(proposed, scale: Self.doubleTapScale, container: container, content: content)
        )
    }

    func panned(by translation: CGSize, container: CGSize, content: CGSize) -> ZoomTransform {
        let proposed = CGSize(width: offset.width + translation.width, height: offset.height + translation.height)
        return ZoomTransform(
            scale: scale,
            offset: Self.clamped(proposed, scale: scale, container: container, content: content)
        )
    }

    static func dismissProgress(for translation: CGSize) -> Double {
        min(max(Double(translation.height) / dismissFlickDistance, 0), 1)
    }

    static func shouldDismiss(translation: CGSize, predictedEnd: CGSize) -> Bool {
        guard translation.height > 0 else { return false }
        return Double(translation.height) > dismissDistance || Double(predictedEnd.height) > dismissFlickDistance
    }

    static func shouldShowInfo(translation: CGSize, predictedEnd: CGSize) -> Bool {
        let up = -Double(translation.height)
        guard up > 0, up > abs(Double(translation.width)) else { return false }
        return up > infoDistance || -Double(predictedEnd.height) > infoFlickDistance
    }

    private static func relativeToCentre(_ point: CGPoint, in container: CGSize) -> CGSize {
        CGSize(width: point.x - container.width / 2, height: point.y - container.height / 2)
    }

    private static func clamped(_ offset: CGSize, scale: Double, container: CGSize, content: CGSize) -> CGSize {
        let maxX = max(0, (content.width * CGFloat(scale) - container.width) / 2)
        let maxY = max(0, (content.height * CGFloat(scale) - container.height) / 2)
        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }
}
