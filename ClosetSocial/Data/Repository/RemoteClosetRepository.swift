import Foundation

public struct RemoteClosetRepository: ClosetRepository {
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
}
