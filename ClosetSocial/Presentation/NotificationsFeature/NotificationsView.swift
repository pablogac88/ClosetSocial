import SwiftUI

public struct NotificationsView: View {
    @Bindable private var viewModel: NotificationsViewModel

    public init(viewModel: NotificationsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            DSColor.background
                .ignoresSafeArea()

            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.notifications.isEmpty {
                    emptyState
                } else {
                    notificationList
                }
            }
        }
        .task { await viewModel.load() }
        .navigationTitle("Actividad")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.unreadCount > 0 {
                    Button {
                        Task { await viewModel.markAllRead() }
                    } label: {
                        Text("Todo leído")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(DSColor.highlight)
                    }
                }
            }
        }
    }

    // MARK: List

    private var notificationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.notifications) { notification in
                    NotificationRow(notification: notification)
                    Divider()
                        .padding(.leading, 76)
                }
            }
            .background(DSColor.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bell")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(DSColor.tertiaryText)
            Text("Sin actividad todavía")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(DSColor.primaryText)
            Text("Aquí verás cuando alguien te siga, comente o dé like a tus publicaciones.")
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(DSColor.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Notification row

private struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                AvatarBubble(
                    displayName: notification.actor.displayName,
                    avatarURL: notification.actor.avatarURL,
                    size: 46,
                    fillColor: DSColor.warmFill,
                    textColor: DSColor.secondaryText
                )

                if !notification.isRead {
                    Circle()
                        .fill(DSColor.highlight)
                        .frame(width: 10, height: 10)
                        .offset(x: 2, y: -2)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(notification.humanText)
                    .font(.system(.subheadline, design: .rounded, weight: notification.isRead ? .regular : .semibold))
                    .foregroundStyle(DSColor.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(notification.createdAt.relativeFormatted)
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(DSColor.tertiaryText)
            }

            Spacer()

            notificationIcon
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            notification.isRead
                ? Color.clear
                : DSColor.highlight.opacity(0.04)
        )
    }

    private var notificationIcon: some View {
        Group {
            switch notification.type {
            case .follow:
                Image(systemName: "person.fill.badge.plus")
                    .foregroundStyle(DSColor.highlight)
            case .like:
                Image(systemName: "heart.fill")
                    .foregroundStyle(DSColor.destructive)
            case .comment:
                Image(systemName: "bubble.right.fill")
                    .foregroundStyle(DSColor.success)
            }
        }
        .font(.system(size: 16))
    }
}

// MARK: - Date helper

private extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}
