import Foundation
import GalleryCore
import GalleryUI
import SwiftUI

@main
struct GalleryApp: App {
    @State private var viewModel = CompositionRoot.makeGalleryViewModel()

    var body: some Scene {
        WindowGroup {
            GalleryRootView(viewModel: viewModel)
        }
    }
}

@MainActor
enum CompositionRoot {
    private static let baseURL = URL(string: "https://api.unsplash.com")!

    static func makeGalleryViewModel() -> GalleryViewModel {
        let client = makeAPIClient()
        let baseURL = baseURL
        let stream = PhotoStream { page in
            let request = UnsplashEndpoint.editorial(page: page).request(baseURL: baseURL)
            let (data, response) = try await client.send(request)
            return try EditorialPhotosMapper.map(data, from: response)
        }
        return GalleryViewModel(loadFeed: { try await stream.firstPage() })
    }

    private static func makeAPIClient() -> HTTPClient {
        let accessKey = Bundle.main.object(forInfoDictionaryKey: "UnsplashAccessKey") as? String ?? ""
        return AuthorizingHTTPClient(
            decoratee: URLSessionHTTPClient(session: URLSession(configuration: .default)),
            accessKey: accessKey
        )
    }
}
