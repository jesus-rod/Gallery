import Foundation
import GalleryCore
import Testing

struct UnsplashRenditionTests {
    @Test func gridURL_keepsRawURLAndItsQueryItems() throws {
        let raw = URL(string: "https://images.unsplash.com/photo-1?ixid=abc&ixlib=rb-4")!

        let components = try components(of: UnsplashRendition.gridURL(raw: raw, pointWidth: 100, scale: 2, quality: 75))

        #expect(components.scheme == "https")
        #expect(components.host == "images.unsplash.com")
        #expect(components.path == "/photo-1")
        #expect(components.queryItems?.contains(URLQueryItem(name: "ixid", value: "abc")) == true)
        #expect(components.queryItems?.contains(URLQueryItem(name: "ixlib", value: "rb-4")) == true)
    }

    @Test func gridURL_addsWidthScaleQualityAndJPEGFormat() throws {
        let raw = URL(string: "https://images.unsplash.com/photo-1?ixid=abc")!

        let components = try components(
            of: UnsplashRendition.gridURL(raw: raw, pointWidth: 195.3, scale: 3, quality: 70))

        #expect(
            Set(components.queryItems ?? []) == [
                URLQueryItem(name: "ixid", value: "abc"),
                URLQueryItem(name: "w", value: "196"),
                URLQueryItem(name: "dpr", value: "3"),
                URLQueryItem(name: "q", value: "70"),
                URLQueryItem(name: "fm", value: "jpg"),
            ])
    }

    @Test func gridURL_replacesExistingSizingItemsInsteadOfDuplicating() throws {
        let raw = URL(string: "https://images.unsplash.com/photo-1?w=1080&fm=webp&q=80&dpr=1&ixid=abc")!

        let components = try components(of: UnsplashRendition.gridURL(raw: raw, pointWidth: 100, scale: 2, quality: 75))

        #expect(
            Set(components.queryItems ?? []) == [
                URLQueryItem(name: "ixid", value: "abc"),
                URLQueryItem(name: "w", value: "100"),
                URLQueryItem(name: "dpr", value: "2"),
                URLQueryItem(name: "q", value: "75"),
                URLQueryItem(name: "fm", value: "jpg"),
            ])
        #expect(components.queryItems?.count == 5)
    }

    private func components(of url: URL) throws -> URLComponents {
        try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    }
}
