import Foundation

public enum UnsplashRendition {
    public static func gridURL(raw: URL, pointWidth: Double, scale: Double, quality: Int) -> URL {
        guard var components = URLComponents(url: raw, resolvingAgainstBaseURL: false) else { return raw }
        let sizing = [
            URLQueryItem(name: "w", value: String(Int(pointWidth.rounded(.up)))),
            URLQueryItem(name: "dpr", value: format(scale)),
            URLQueryItem(name: "q", value: String(quality)),
            URLQueryItem(name: "fm", value: "jpg"),
        ]
        let sizingNames = Set(sizing.map(\.name))
        let kept = (components.queryItems ?? []).filter { !sizingNames.contains($0.name) }
        components.queryItems = kept + sizing
        return components.url ?? raw
    }

    private static func format(_ scale: Double) -> String {
        scale == scale.rounded() ? String(Int(scale)) : String(scale)
    }
}
