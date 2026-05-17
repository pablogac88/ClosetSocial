import Foundation

public struct RemoteClosetRepository: ClosetRepository, CatalogRepository {
    private let sender: RemoteRequestSender

    public init(client: any HTTPClient, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.sender = RemoteRequestSender(client: client, encoder: encoder, decoder: decoder)
    }

    public func fetchCloset(token: String) async throws -> [Garment] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.closet,
            method: .get,
            token: token,
            as: ClosetResponseDTO.self
        )
        return dto.items.map { $0.toDomain() }
    }

    public func fetchGarmentTypes(token: String) async throws -> [GarmentType] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.catalogGarmentTypes,
            method: .get,
            token: token,
            as: [GarmentTypeOptionDTO].self
        )
        return dto.map { $0.toDomain() }
    }

    public func fetchGarmentCategories(token: String) async throws -> [GarmentCategory] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.catalogGarmentCategories,
            method: .get,
            token: token,
            as: [GarmentCategoryResponseDTO].self
        )
        return dto.map { $0.toDomain() }
    }

    public func fetchBrands(token: String) async throws -> [Brand] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.catalogBrands,
            method: .get,
            token: token,
            as: [BrandResponseDTO].self
        )
        return dto.map { $0.toDomain() }
    }

    public func createGarment(token: String, garment: NewGarment) async throws -> Garment {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.closet,
            method: .post,
            body: garment.toDTO(),
            token: token,
            as: GarmentDTO.self
        )
        return dto.toDomain()
    }

    public func deleteGarment(token: String, id: UUID) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.garment(id: id),
            method: .delete,
            token: token
        )
    }
}
