import Foundation

public struct RemoteSearchRepository: SearchRepository {
    private let sender: RemoteRequestSender

    public init(client: any HTTPClient, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.sender = RemoteRequestSender(client: client, encoder: encoder, decoder: decoder)
    }

    public func search(token: String, query: String) async throws -> SearchResults {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.search,
            method: .get,
            token: token,
            queryItems: [.init(name: "q", value: query)],
            as: SearchResultsDTO.self
        )
        return dto.toDomain()
    }
}
