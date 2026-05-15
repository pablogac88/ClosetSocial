import SwiftUI

public struct NotificationsView: View {
    @Bindable private var viewModel: NotificationsViewModel

    public init(viewModel: NotificationsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.975, green: 0.970, blue: 0.962)
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
                            .foregroundStyle(Color(red: 0.25, green: 0.30, blue: 0.58))
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
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                .foregroundStyle(Color(red: 0.72, green: 0.66, blue: 0.60))
            Text("Sin actividad todavía")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(red: 0.28, green: 0.24, blue: 0.22))
            Text("Aquí verás cuando alguien te siga, comente o dé like a tus publicaciones.")
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(Color(red: 0.58, green: 0.52, blue: 0.48))
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
                    fillColor: Color(red: 0.91, green: 0.87, blue: 0.82),
                    textColor: Color(red: 0.44, green: 0.38, blue: 0.32)
                )

                if !notification.isRead {
                    Circle()
                        .fill(Color(red: 0.25, green: 0.30, blue: 0.58))
                        .frame(width: 10, height: 10)
                        .offset(x: 2, y: -2)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(notification.humanText)
                    .font(.system(.subheadline, design: .rounded, weight: notification.isRead ? .regular : .semibold))
                    .foregroundStyle(Color(red: 0.14, green: 0.11, blue: 0.09))
                    .fixedSize(horizontal: false, vertical: true)

                Text(notification.createdAt.relativeFormatted)
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(Color(red: 0.68, green: 0.62, blue: 0.56))
            }

            Spacer()

            notificationIcon
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            notification.isRead
                ? Color.clear
                : Color(red: 0.25, green: 0.30, blue: 0.58).opacity(0.04)
        )
    }

    private var notificationIcon: some View {
        Group {
            switch notification.type {
            case .follow:
                Image(systemName: "person.fill.badge.plus")
                    .foregroundStyle(Color(red: 0.25, green: 0.30, blue: 0.58))
            case .like:
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color(red: 0.82, green: 0.25, blue: 0.28))
            case .comment:
                Image(systemName: "bubble.right.fill")
                    .foregroundStyle(Color(red: 0.25, green: 0.58, blue: 0.42))
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
