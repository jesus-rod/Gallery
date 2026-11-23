import Foundation
import GalleryCore
import Testing

@testable import GalleryUI

struct CaptionTests {
    @Test func usesAltDescriptionWhenPresent() {
        let photo = makePhoto(description: "A description", altDescription: "An alt description")

        #expect(caption(for: photo) == "An alt description")
    }

    @Test func fallsBackToDescriptionWithoutAltDescription() {
        let photo = makePhoto(description: "A description", altDescription: nil)

        #expect(caption(for: photo) == "A description")
    }

    @Test func usesPlaceholderWithoutAnyDescription() {
        let photo = makePhoto(description: nil, altDescription: nil)

        #expect(caption(for: photo) == "Untitled photo")
    }

    @Test(arguments: ["", "  ", "\n\t"])
    func treatsBlankTextAsMissing(blank: String) {
        #expect(caption(for: makePhoto(description: "A description", altDescription: blank)) == "A description")
        #expect(caption(for: makePhoto(description: blank, altDescription: nil)) == "Untitled photo")
    }
}

private func makePhoto(description: String? = nil, altDescription: String? = nil) -> Photo {
    Photo(
        id: "any-id",
        width: 1,
        height: 1,
        blurHash: nil,
        description: description,
        altDescription: altDescription,
        renditions: Photo.Renditions(
            raw: URL(string: "https://images.unsplash.com/raw")!,
            small: URL(string: "https://images.unsplash.com/small")!,
            regular: URL(string: "https://images.unsplash.com/regular")!
        ),
        photographer: Photo.Photographer(name: "A photographer", profileURL: URL(string: "https://unsplash.com/@a")!)
    )
}
