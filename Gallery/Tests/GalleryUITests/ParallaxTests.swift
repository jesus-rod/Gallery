import CoreGraphics
import Testing

@testable import GalleryUI

struct ParallaxTests {
    @Test func doesNotMoveACentredPage() {
        #expect(Parallax.offset(pageMinX: 0, pageWidth: 400, factor: 0.3) == 0)
    }

    @Test func lagsBehindAPageOneScreenAway() {
        #expect(Parallax.offset(pageMinX: 400, pageWidth: 400, factor: 0.25) == -100)
        #expect(Parallax.offset(pageMinX: -400, pageWidth: 400, factor: 0.25) == 100)
        #expect(Parallax.offset(pageMinX: 200, pageWidth: 400, factor: 0.25) == -50)
    }

    @Test func clampsBeyondOnePage() {
        #expect(Parallax.offset(pageMinX: 1200, pageWidth: 400, factor: 0.25) == -100)
        #expect(Parallax.offset(pageMinX: -900, pageWidth: 400, factor: 0.25) == 100)
    }
}
