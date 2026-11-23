import CoreGraphics
import Testing

@testable import GalleryUI

struct ContentFitTests {
    @Test func fitsALandscapePhotoToTheContainerWidth() {
        let size = ContentFit.size(of: makePhoto(width: 2000, height: 1000), in: CGSize(width: 400, height: 800))

        #expect(size == CGSize(width: 400, height: 200))
    }

    @Test func fitsAPortraitPhotoToTheContainerHeight() {
        let size = ContentFit.size(of: makePhoto(width: 1000, height: 2000), in: CGSize(width: 400, height: 300))

        #expect(size == CGSize(width: 150, height: 300))
    }

    @Test func fitsAPhotoWithNoSizeAsASquare() {
        let size = ContentFit.size(of: makePhoto(width: 0, height: 0), in: CGSize(width: 400, height: 300))

        #expect(size == CGSize(width: 300, height: 300))
    }
}
