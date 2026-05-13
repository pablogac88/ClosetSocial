import Foundation

public struct RemoteTimelineRepository: TimelineRepository {
    private let sender: RemoteRequestSender

    public init(client: any HTTPClient, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.sender = RemoteRequestSender(client: client, encoder: encoder, decoder: decoder)
    }

    public func fetchTimeline(token: String) async throws -> [FeedPost] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.timeline,
            method: .get,
            token: token,
            as: TimelineResponseDTO.self
        )
        return dto.items.map { $0.toDomain() }
    }
}
