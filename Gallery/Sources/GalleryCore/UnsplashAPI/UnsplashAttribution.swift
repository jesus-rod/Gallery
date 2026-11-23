import Foundation

public enum UnsplashAttribution {
    public static func referralURL(_ url: URL, appName: String) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        let referral = [
            URLQueryItem(name: "utm_source", value: appName),
            URLQueryItem(name: "utm_medium", value: "referral"),
        ]
        let referralNames = Set(referral.map(\.name))
        let kept = (components.queryItems ?? []).filter { !referralNames.contains($0.name) }
        components.queryItems = kept + referral
        return components.url ?? url
    }

    public static func unsplashURL(appName: String) -> URL {
        referralURL(URL(string: "https://unsplash.com/")!, appName: appName)
    }
}
