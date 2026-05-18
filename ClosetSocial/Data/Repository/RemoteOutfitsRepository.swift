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

    public func createOutfit(token: String, request: CreateOutfitRequest) async throws -> Outfit {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.outfits,
            method: .post,
            body: request.toDTO(),
            token: token,
            as: OutfitDTO.self
        )
        return dto.toDomain()
    }

    public func fetchSavedOutfits(token: String) async throws -> [Outfit] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.savedOutfits,
            method: .get,
            token: token,
            as: OutfitsResponseDTO.self
        )
        return dto.items.map { $0.toDomain() }
    }

    public func deleteOutfit(token: String, id: UUID) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.outfit(id: id),
            method: .delete,
            token: token
        )
    }

    public func saveOutfit(token: String, id: UUID) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.outfitSave(id: id),
            method: .post,
            token: token
        )
    }

    public func unsaveOutfit(token: String, id: UUID) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.outfitSave(id: id),
            method: .delete,
            token: token
        )
    }
}
