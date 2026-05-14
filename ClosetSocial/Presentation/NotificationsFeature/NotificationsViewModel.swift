import Foundation
import Observation

@MainActor
@Observable
public final class NotificationsViewModel {
    public typealias TokenProvider = @MainActor () -> String?

    public private(set) var notifications: [AppNotification] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    public var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    private let repository: any NotificationRepository
    private let tokenProvider: TokenProvider

    public init(repository: any NotificationRepository, tokenProvider: @escaping TokenProvider) {
        self.repository = repository
        self.tokenProvider = tokenProvider
    }

    public func load() async {
        guard let token = tokenProvider() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            notifications = try await repository.fetchNotifications(token: token)
        } catch {
            errorMessage = error.userMessage
        }
    }

    public func markAllRead() async {
        guard let token = tokenProvider() else { return }
        do {
            try await repository.markAllRead(token: token)
            notifications = notifications.map { notification in
                guard !notification.isRead else { return notification }
                return AppNotification(
                    id: notification.id,
                    type: notification.type,
                    actor: notification.actor,
                    postID: notification.postID,
                    createdAt: notification.createdAt,
                    readAt: .now
                )
            }
        } catch {
            errorMessage = error.userMessage
        }
    }
}
