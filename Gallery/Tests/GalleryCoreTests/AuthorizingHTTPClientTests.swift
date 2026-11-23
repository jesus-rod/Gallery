import Foundation
import GalleryCore
import Testing

struct AuthorizingHTTPClientTests {
    @Test func send_addsAuthorizationHeadersKeepingTheOriginalRequest() async throws {
        let client = HTTPClientSpy(result: .success((Data(), HTTPURLResponse(statusCode: 200))))
        let sut = AuthorizingHTTPClient(decoratee: client, accessKey: "an-access-key")
        var request = URLRequest(url: URL(string: "https://any-url.com/photos?page=1")!)
        request.setValue("an-etag", forHTTPHeaderField: "If-None-Match")

        _ = try await sut.send(request)

        let sent = try #require(await client.requests.first)
        #expect(sent.url == request.url)
        #expect(sent.value(forHTTPHeaderField: "If-None-Match") == "an-etag")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Client-ID an-access-key")
        #expect(sent.value(forHTTPHeaderField: "Accept-Version") == "v1")
    }

    @Test func send_deliversTheDecorateeResponse() async throws {
        let data = Data("any data".utf8)
        let response = HTTPURLResponse(statusCode: 403, headers: ["X-Ratelimit-Remaining": "0"])
        let sut = AuthorizingHTTPClient(
            decoratee: HTTPClientSpy(result: .success((data, response))), accessKey: "an-access-key")

        let (receivedData, receivedResponse) = try await sut.send(anyRequest())

        #expect(receivedData == data)
        #expect(receivedResponse === response)
    }

    @Test func send_rethrowsTheDecorateeError() async {
        let error = URLError(.notConnectedToInternet)
        let sut = AuthorizingHTTPClient(decoratee: HTTPClientSpy(result: .failure(error)), accessKey: "an-access-key")

        await #expect(throws: error) {
            try await sut.send(anyRequest())
        }
    }

    @Test func descriptions_doNotRevealTheAccessKey() {
        let sut = AuthorizingHTTPClient(
            decoratee: HTTPClientSpy(result: .failure(URLError(.unknown))), accessKey: "an-access-key")
        var dumped = ""
        dump(sut, to: &dumped)

        #expect(!String(describing: sut).contains("an-access-key"))
        #expect(!String(reflecting: sut).contains("an-access-key"))
        #expect(!dumped.contains("an-access-key"))
    }

    private func anyRequest() -> URLRequest {
        URLRequest(url: URL(string: "https://any-url.com")!)
    }
}

actor HTTPClientSpy: HTTPClient {
    private(set) var requests: [URLRequest] = []
    private let result: Result<(Data, HTTPURLResponse), Error>

    init(result: Result<(Data, HTTPURLResponse), Error>) {
        self.result = result
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        return try result.get()
    }
}
