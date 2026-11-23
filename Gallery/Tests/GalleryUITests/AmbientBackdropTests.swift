import Testing

@testable import GalleryUI

struct AmbientBackdropTests {
    @Test func isFullyVisibleWithTheChromeShownAndNoDrag() {
        #expect(AmbientBackdrop.opacity(isChromeVisible: true, dismissProgress: 0, reduceTransparency: false) == 1)
    }

    @Test func fadesToBlackWhenTheChromeIsHidden() {
        #expect(AmbientBackdrop.opacity(isChromeVisible: false, dismissProgress: 0, reduceTransparency: false) == 0)
    }

    @Test func fadesWithTheDismissDrag() {
        #expect(AmbientBackdrop.opacity(isChromeVisible: true, dismissProgress: 0.5, reduceTransparency: false) == 0.5)
        #expect(AmbientBackdrop.opacity(isChromeVisible: true, dismissProgress: 1, reduceTransparency: false) == 0)
    }

    @Test func isOffWithReduceTransparency() {
        #expect(AmbientBackdrop.opacity(isChromeVisible: true, dismissProgress: 0, reduceTransparency: true) == 0)
    }
}
