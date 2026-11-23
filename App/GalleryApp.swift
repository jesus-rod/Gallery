import Foundation
import GalleryCore
import GalleryImageLoading
import GalleryUI
import SwiftUI
import UIKit

@main
struct GalleryApp: App {
    @State private var viewModel = CompositionRoot.makeGalleryViewModel()
    private let imagePipeline = CompositionRoot.makeImagePipeline()

    var body: some Scene {
        WindowGroup {
            GalleryRootView(
                viewModel: viewModel,
                images: imagePipeline.photoImages,
                referralAppName: "gallery_ios"
            )
            .task { imagePipeline.evictDiskCache() }
            .onReceive(memoryWarnings) { _ in imagePipeline.clearMemoryCache() }
        }
    }

    private var memoryWarnings: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
    }
}

@MainActor
enum CompositionRoot {
    private static let baseURL = URL(string: "https://api.unsplash.com")!

    static func makeGalleryViewModel() -> GalleryViewModel {
        let client = makeAPIClient()
        let baseURL = baseURL
        let feedStream = PhotoStream { page in
            let request = UnsplashEndpoint.editorial(page: page).request(baseURL: baseURL)
            let (data, response) = try await client.send(request)
            return try EditorialPhotosMapper.map(data, from: response)
        }
        return GalleryViewModel(
            loadFeed: { try await feedStream.firstPage() },
            search: { query in
                let searchStream = PhotoStream { page in
                    let request = UnsplashEndpoint.search(query: query, page: page).request(baseURL: baseURL)
                    let (data, response) = try await client.send(request)
                    return try SearchPhotosMapper.map(data, from: response)
                }
                return try await searchStream.firstPage()
            }
        )
    }

    static func makeImagePipeline() -> ImagePipeline {
        let client = makeImageClient()
        return ImagePipeline(
            fetch: { url in try await client.send(URLRequest(url: url)) },
            directory: URL.cachesDirectory.appending(path: "Renditions", directoryHint: .isDirectory),
            configuration: .default
        )
    }

    private static func makeAPIClient() -> HTTPClient {
        #if DEBUG
            if isUsingStubs {
                return StubHTTPClient()
            }
        #endif
        let accessKey = Bundle.main.object(forInfoDictionaryKey: "UnsplashAccessKey") as? String ?? ""
        return AuthorizingHTTPClient(
            decoratee: URLSessionHTTPClient(session: URLSession(configuration: .default)),
            accessKey: accessKey
        )
    }

    private static func makeImageClient() -> HTTPClient {
        #if DEBUG
            if isUsingStubs {
                return StubImageHTTPClient()
            }
        #endif
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        return URLSessionHTTPClient(session: URLSession(configuration: configuration))
    }

    private static var isUsingStubs: Bool {
        ProcessInfo.processInfo.arguments.contains("-useStubs")
    }
}
