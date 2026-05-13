import Foundation

public struct RemoteOutfitsRepository: OutfitsRepository {
    private let sender: RemoteRequestSender

    public init(client: any HTTPClient, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.sender = RemoteRequestSender(client: client, encoder: encoder, decoder: decoder)
    }

    public func fetchOutfits(token: String) async throws -> [Outfit] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.outfits,
            method: .get,
            token: token,
            as: OutfitsResponseDTO.self
        )
        return dto.items.map { $0.toDomain() }
    }
}
