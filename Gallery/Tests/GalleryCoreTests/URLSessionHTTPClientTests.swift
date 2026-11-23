import Foundation
import GalleryCore
import Testing

struct URLSessionHTTPClientTests {
    private let url = URL(string: "https://\(UUID().uuidString).com/photos")!

    @Test func send_performsTheGivenRequest() async throws {
        URLProtocolStub.stub(url: url, data: Data(), response: HTTPURLResponse(url: url, statusCode: 200))
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("a-value", forHTTPHeaderField: "A-Header")

        _ = try await makeSUT().send(request)

        let received = URLProtocolStub.requests(for: url)
        #expect(received.count == 1)
        #expect(received.first?.httpMethod == "GET")
        #expect(received.first?.value(forHTTPHeaderField: "A-Header") == "a-value")
    }

    @Test func send_deliversDataAndResponseOnHTTPURLResponse() async throws {
        let data = Data("any data".utf8)
        let response = HTTPURLResponse(url: url, statusCode: 201)
        URLProtocolStub.stub(url: url, data: data, response: response)

        let (receivedData, receivedResponse) = try await makeSUT().send(URLRequest(url: url))

        #expect(receivedData == data)
        #expect(receivedResponse.url == response.url)
        #expect(receivedResponse.statusCode == response.statusCode)
    }

    @Test func send_throwsOnTransportError() async {
        URLProtocolStub.stub(url: url, error: URLError(.notConnectedToInternet))

        await #expect {
            try await makeSUT().send(URLRequest(url: url))
        } throws: { error in
            (error as? URLError)?.code == .notConnectedToInternet
        }
    }

    @Test func send_throwsOnNonHTTPURLResponse() async {
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        URLProtocolStub.stub(url: url, data: Data(), response: response)

        await #expect(throws: URLSessionHTTPClient.UnexpectedResponse.self) {
            try await makeSUT().send(URLRequest(url: url))
        }
    }

    private func makeSUT() -> URLSessionHTTPClient {
        URLSessionHTTPClient(session: URLProtocolStub.makeSession())
    }
}

extension HTTPURLResponse {
    fileprivate convenience init(url: URL, statusCode: Int) {
        self.init(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
