import Foundation

/// Punto de entrada de la capa Data.
/// Crea un set coherente de repositorios remotos compartiendo cliente HTTP y codificadores.
public struct RemoteRepositories: Sendable {
    public let auth: any AuthRepository
    public let timeline: any TimelineRepository
    public let search: any SearchRepository
    public let closet: any ClosetRepository
    public let outfits: any OutfitsRepository
    public let profile: any ProfileRepository
    public let notifications: any NotificationRepository
    public let upload: any UploadRepository

    public init(client: any HTTPClient, baseURL: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        self.auth = RemoteAuthRepository(client: client, encoder: encoder, decoder: decoder)
        self.timeline = RemoteTimelineRepository(client: client, encoder: encoder, decoder: decoder)
        self.search = RemoteSearchRepository(client: client, encoder: encoder, decoder: decoder)
        self.closet = RemoteClosetRepository(client: client, encoder: encoder, decoder: decoder)
        self.outfits = RemoteOutfitsRepository(client: client, encoder: encoder, decoder: decoder)
        self.profile = RemoteProfileRepository(client: client, encoder: encoder, decoder: decoder)
        self.notifications = RemoteNotificationRepository(client: client, encoder: encoder, decoder: decoder)
        self.upload = RemoteUploadRepository(baseURL: baseURL, decoder: decoder)
    }
}
