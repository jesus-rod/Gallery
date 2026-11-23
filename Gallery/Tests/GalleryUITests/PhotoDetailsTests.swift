import Foundation
import GalleryCore
import Testing

@testable import GalleryUI

struct PhotoDetailsTests {
    @Test func omitsTheDescriptionWhenItIsTheCaption() {
        let photo = makePhoto(description: "A red door", altDescription: nil)

        #expect(PhotoDetails(photo).description == nil)
    }

    @Test func showsTheDescriptionWhenItDiffersFromTheCaption() {
        let photo = makePhoto(description: "Shot at dawn in Lisbon", altDescription: "a red door")

        let details = PhotoDetails(photo)

        #expect(details.caption == "a red door")
        #expect(details.description == "Shot at dawn in Lisbon")
    }

    @Test func describesTheSizeInPixelsAndWholeMegapixelsFromTen() {
        let details = PhotoDetails(makePhoto(width: 6000, height: 4000))

        #expect(details.size == "6000 × 4000 · 24 MP")
    }

    @Test func describesSmallPhotosWithOneDecimalMegapixel() {
        #expect(PhotoDetails(makePhoto(width: 640, height: 480)).size == "640 × 480 · 0.3 MP")
        #expect(PhotoDetails(makePhoto(width: 3000, height: 2000)).size == "3000 × 2000 · 6 MP")
        #expect(PhotoDetails(makePhoto(width: 2500, height: 1700)).size == "2500 × 1700 · 4.3 MP")
    }
}
