import CoreGraphics

struct HeroStretch: Equatable {
    let height: CGFloat
    let offset: CGFloat

    init(minY: CGFloat, baseHeight: CGFloat) {
        let pull = max(minY, 0)
        height = baseHeight + pull
        offset = minY > 0 ? -pull : -minY / 2
    }
}
