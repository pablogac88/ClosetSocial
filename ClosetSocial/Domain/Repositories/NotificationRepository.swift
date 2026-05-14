import Foundation

public protocol NotificationRepository: Sendable {
    func fetchNotifications(token: String) async throws -> [AppNotification]
    func markRead(id: UUID, token: String) async throws
    func markAllRead(token: String) async throws
}
