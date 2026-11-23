import Foundation
import GalleryCore
import SwiftUI

struct PhotoCreditView: View {
    let photographer: Photo.Photographer
    let appName: String

    var body: some View {
        Text(credit)
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("photo-credit")
    }

    private var credit: AttributedString {
        var name = AttributedString(photographer.name)
        name.link = UnsplashAttribution.referralURL(photographer.profileURL, appName: appName)
        var unsplash = AttributedString("Unsplash")
        unsplash.link = UnsplashAttribution.unsplashURL(appName: appName)
        var text = AttributedString(String(localized: "Photo by %1$@ on %2$@", bundle: .module))
        if let range = text.range(of: "%2$@") {
            text.replaceSubrange(range, with: unsplash)
        }
        if let range = text.range(of: "%1$@") {
            text.replaceSubrange(range, with: name)
        }
        return text
    }
}
