import CoreGraphics
import Testing

@testable import GalleryUI

struct HeroStretchTests {
    @Test func keepsItsBaseHeightAtRest() {
        let stretch = HeroStretch(minY: 0, baseHeight: 500)

        #expect(stretch.height == 500)
        #expect(stretch.offset == 0)
    }

    @Test func growsFromAPinnedTopWhenPulledDown() {
        let stretch = HeroStretch(minY: 100, baseHeight: 500)

        #expect(stretch.height == 600)
        #expect(stretch.offset == -100)
    }

    @Test func driftsAtHalfSpeedWhenScrolledUp() {
        let stretch = HeroStretch(minY: -100, baseHeight: 500)

        #expect(stretch.height == 500)
        #expect(stretch.offset == 50)
    }

    @Test(arguments: [
        (CGSize(width: 402, height: 874), 524.0),
        (CGSize(width: 834, height: 1210), 480.0),
        (CGSize(width: 874, height: 402), 201.0),
    ])
    func heroHeightIsMostOfAPhoneCappedOnIPadAndHalfInLandscape(container: CGSize, expected: CGFloat) {
        #expect(Design.Hero.height(for: container) == expected)
    }
}
