import Foundation
import GalleryCore
import Testing

struct UnsplashAttributionTests {
    @Test func referralURL_addsTheAppNameAsSourceAndReferralAsMedium() throws {
        let url = URL(string: "https://unsplash.com/@jane")!

        let components = try components(of: UnsplashAttribution.referralURL(url, appName: "gallery_ios"))

        #expect(components.scheme == "https")
        #expect(components.host == "unsplash.com")
        #expect(components.path == "/@jane")
        #expect(
            Set(components.queryItems ?? []) == [
                URLQueryItem(name: "utm_source", value: "gallery_ios"),
                URLQueryItem(name: "utm_medium", value: "referral"),
            ])
    }

    @Test func referralURL_keepsExistingQueryItems() throws {
        let url = URL(string: "https://unsplash.com/@jane?lang=en")!

        let components = try components(of: UnsplashAttribution.referralURL(url, appName: "gallery_ios"))

        #expect(components.queryItems?.contains(URLQueryItem(name: "lang", value: "en")) == true)
        #expect(components.queryItems?.count == 3)
    }

    @Test func referralURL_replacesExistingReferralItemsInsteadOfDuplicating() throws {
        let url = URL(string: "https://unsplash.com/@jane?utm_source=old&utm_medium=email")!

        let components = try components(of: UnsplashAttribution.referralURL(url, appName: "gallery_ios"))

        #expect(
            Set(components.queryItems ?? []) == [
                URLQueryItem(name: "utm_source", value: "gallery_ios"),
                URLQueryItem(name: "utm_medium", value: "referral"),
            ])
        #expect(components.queryItems?.count == 2)
    }

    @Test func unsplashURL_pointsToTheUnsplashHomePageWithReferralItems() throws {
        let components = try components(of: UnsplashAttribution.unsplashURL(appName: "gallery_ios"))

        #expect(components.host == "unsplash.com")
        #expect(components.path == "/")
        #expect(
            Set(components.queryItems ?? []) == [
                URLQueryItem(name: "utm_source", value: "gallery_ios"),
                URLQueryItem(name: "utm_medium", value: "referral"),
            ])
    }

    private func components(of url: URL) throws -> URLComponents {
        try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    }
}
