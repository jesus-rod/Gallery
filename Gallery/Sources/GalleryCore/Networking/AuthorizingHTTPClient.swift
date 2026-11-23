import Foundation

public struct AuthorizingHTTPClient: HTTPClient {
    private let decoratee: HTTPClient
    private let accessKey: String

    public init(decoratee: HTTPClient, accessKey: String) {
        self.decoratee = decoratee
        self.accessKey = accessKey
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var authorized = request
        authorized.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        authorized.setValue("v1", forHTTPHeaderField: "Accept-Version")
        return try await decoratee.send(authorized)
    }
}

extension AuthorizingHTTPClient: CustomReflectable {
    public var customMirror: Mirror {
        Mirror(self, children: [:])
    }
}
