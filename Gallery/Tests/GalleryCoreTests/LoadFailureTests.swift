import Foundation
import GalleryCore
import Testing

struct LoadFailureTests {
    @Test(arguments: [
        URLError.Code.notConnectedToInternet,
        .networkConnectionLost,
        .dataNotAllowed,
        .timedOut,
    ])
    func classifiesConnectivityErrorsAsOffline(code: URLError.Code) {
        #expect(LoadFailure(URLError(code)) == .offline)
    }

    @Test(arguments: [
        (UnsplashAPIError.rateLimited, LoadFailure.rateLimited),
        (.unauthorized, .unauthorized),
        (.invalidData, .other),
    ])
    func classifiesAPIErrors(error: UnsplashAPIError, expected: LoadFailure) {
        #expect(LoadFailure(error) == expected)
    }

    @Test func classifiesOtherURLErrorsAsOther() {
        #expect(LoadFailure(URLError(.badServerResponse)) == .other)
    }

    @Test func classifiesUnrelatedErrorsAsOther() {
        #expect(LoadFailure(UnrelatedError()) == .other)
    }
}

private struct UnrelatedError: Error {}
