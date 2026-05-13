import Foundation
import Domain
import Networking

/// Punto de entrada de la capa Data.
/// Crea un set coherente de repositorios remotos compartiendo cliente HTTP y codificadores.
public struct RemoteRepositories: Sendable {
    public let auth: any AuthRepository
    public let timeline: any TimelineRepository
    public let closet: any ClosetRepository
    public let outfits: any OutfitsRepository
    public let profile: any ProfileRepository

    public init(client: any HTTPClient) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        self.auth = RemoteAuthRepository(client: client, encoder: encoder, decoder: decoder)
        self.timeline = RemoteTimelineRepository(client: client, encoder: encoder, decoder: decoder)
        self.closet = RemoteClosetRepository(client: client, encoder: encoder, decoder: decoder)
        self.outfits = RemoteOutfitsRepository(client: client, encoder: encoder, decoder: decoder)
        self.profile = RemoteProfileRepository(client: client, encoder: encoder, decoder: decoder)
    }
}
