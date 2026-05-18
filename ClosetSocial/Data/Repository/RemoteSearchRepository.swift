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

public struct RemoteExploreRepository: ExploreRepository {
    private let sender: RemoteRequestSender

    public init(client: any HTTPClient, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.sender = RemoteRequestSender(client: client, encoder: encoder, decoder: decoder)
    }

    public func fetchDiscoverOutfits(token: String, limit: Int) async throws -> [ExploreOutfitItem] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.discoverOutfits,
            method: .get,
            token: token,
            queryItems: [.init(name: "limit", value: String(limit))],
            as: DiscoverOutfitsResponseDTO.self
        )
        return dto.toDomain()
    }

    public func fetchDiscoverGarments(token: String, limit: Int) async throws -> [ExploreGarmentItem] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.discoverGarments,
            method: .get,
            token: token,
            queryItems: [.init(name: "limit", value: String(limit))],
            as: DiscoverGarmentsResponseDTO.self
        )
        return dto.toDomain()
    }

    public func fetchDiscoverUsers(token: String, limit: Int) async throws -> [ExploreUserItem] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.discoverUsers,
            method: .get,
            token: token,
            queryItems: [.init(name: "limit", value: String(limit))],
            as: DiscoverUsersResponseDTO.self
        )
        return dto.toDomain()
    }

    public func search(token: String, query: String) async throws -> ExploreSearchResults {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.search,
            method: .get,
            token: token,
            queryItems: [.init(name: "q", value: query)],
            as: SearchResultsDTO.self
        )
        return dto.toExploreDomain()
    }
}
