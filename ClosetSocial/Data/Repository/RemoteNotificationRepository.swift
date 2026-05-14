import Foundation

public struct RemoteNotificationRepository: NotificationRepository {
    private let sender: RemoteRequestSender

    public init(client: any HTTPClient, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.sender = RemoteRequestSender(client: client, encoder: encoder, decoder: decoder)
    }

    public func fetchNotifications(token: String) async throws -> [AppNotification] {
        let dtos = try await sender.send(
            path: ClosetSocialEndpoint.notifications,
            method: .get,
            token: token,
            as: [NotificationDTO].self
        )
        return dtos.map { $0.toDomain() }
    }

    public func markRead(id: UUID, token: String) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.notificationRead(id: id),
            method: .patch,
            token: token
        )
    }

    public func markAllRead(token: String) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.notificationsReadAll,
            method: .patch,
            token: token
        )
    }
}
