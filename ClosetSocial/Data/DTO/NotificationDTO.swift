import Foundation

struct NotificationDTO: Codable, Sendable {
    let id: UUID
    let type: String
    let actor: UserDTO
    let postID: UUID?
    let createdAt: Date
    let readAt: Date?
}

extension NotificationDTO {
    func toDomain() -> AppNotification {
        AppNotification(
            id: id,
            type: AppNotificationType(rawValue: type) ?? .like,
            actor: actor.toDomain(),
            postID: postID,
            createdAt: createdAt,
            readAt: readAt
        )
    }
}
