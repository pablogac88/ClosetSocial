import Foundation
import Testing
@testable import Data
import Domain
import Networking

actor StubHTTPClient: HTTPClient {
    private(set) var lastPath: String?
    private(set) var lastMethod: HTTPMethod?
    private(set) var lastBearerToken: String?
    private let nextResponse: HTTPClientResponse

    init(nextResponse: HTTPClientResponse) {
        self.nextResponse = nextResponse
    }

    func send(_ request: HTTPRequest) async throws -> HTTPClientResponse {
        lastPath = request.path
        lastMethod = request.method
        lastBearerToken = request.bearerToken
        return nextResponse
    }
}

@Test("RemoteTimelineRepository pega a api/timeline")
func remoteTimelineRepositoryHitsCorrectEndpoint() async throws {
    let body = Data("{\"items\":[]}".utf8)
    let client = StubHTTPClient(nextResponse: HTTPClientResponse(status: 200, data: body))
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let repository = RemoteTimelineRepository(client: client, encoder: encoder, decoder: decoder)
    let items = try await repository.fetchTimeline(token: "abc")

    let lastPath = await client.lastPath
    let lastToken = await client.lastBearerToken

    #expect(items.isEmpty)
    #expect(lastPath == "api/timeline")
    #expect(lastToken == "abc")
}
