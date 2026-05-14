import Foundation

public enum AppNotificationType: String, Sendable, Codable {
    case follow
    case like
    case comment
}

public struct AppNotification: Identifiable, Sendable {
    public let id: UUID
    public let type: AppNotificationType
    public let actor: User
    public let postID: UUID?
    public let createdAt: Date
    public let readAt: Date?

    public var isRead: Bool { readAt != nil }

    public var humanText: String {
        switch type {
        case .follow:  "\(actor.displayName) empezó a seguirte"
        case .like:    "\(actor.displayName) le dio like a tu publicación"
        case .comment: "\(actor.displayName) comentó tu publicación"
        }
    }
}
