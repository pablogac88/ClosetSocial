import SwiftUI

public struct ConversationsView: View {
    @Bindable private var viewModel: ConversationsViewModel
    private let makeChatDetailViewModel: (Conversation) -> ChatDetailViewModel

    public init(
        viewModel: ConversationsViewModel,
        makeChatDetailViewModel: @escaping (Conversation) -> ChatDetailViewModel
    ) {
        self.viewModel = viewModel
        self.makeChatDetailViewModel = makeChatDetailViewModel
    }

    public var body: some View {
        content
            .background(DSColor.background.ignoresSafeArea())
            .navigationTitle("Mensajes")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.start() }
            .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .content(conversations):
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(conversations) { preview in
                        NavigationLink {
                            ChatDetailView(
                                viewModel: makeChatDetailViewModel(preview.asConversation)
                            )
                        } label: {
                            ConversationRow(preview: preview)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 78)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(DSColor.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(DSColor.border.opacity(0.85), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        case .empty:
            EmptyStateView(
                icon: "bubble.left.and.bubble.right",
                title: "Sin conversaciones todavía",
                message: "Cuando empieces a escribirte con alguien, tus chats aparecerán aquí."
            )
        case let .error(message):
            ContentUnavailableView(
                "No hemos podido cargar tus conversaciones",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }
}

private struct ConversationRow: View {
    let preview: ConversationPreview

    var body: some View {
        HStack(spacing: 14) {
            AvatarBubble(
                displayName: preview.otherParticipant.displayName,
                avatarURL: preview.otherParticipant.avatarURL,
                size: 54,
                fillColor: DSColor.warmFill,
                textColor: DSColor.secondaryText
            )

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(preview.otherParticipant.displayName)
                        .font(.system(.subheadline, design: .rounded, weight: preview.hasUnread ? .bold : .semibold))
                        .foregroundStyle(DSColor.primaryText)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if let lastMessageAt = preview.lastMessageAt {
                        Text(lastMessageAt.chatRelativeTimestamp)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(DSColor.tertiaryText)
                    }
                }

                HStack(spacing: 10) {
                    Text(preview.lastMessage ?? "Todavía no hay mensajes")
                        .font(.system(.subheadline, design: .rounded, weight: preview.hasUnread ? .semibold : .regular))
                        .foregroundStyle(preview.hasUnread ? DSColor.primaryText : DSColor.secondaryText)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    if preview.unreadCount > 0 {
                        Text("\(preview.unreadCount)")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(DSColor.actionPrimaryForeground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(DSColor.actionPrimaryBackground)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private extension Date {
    var chatRelativeTimestamp: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return formatted(date: .omitted, time: .shortened)
        }
        if calendar.isDateInYesterday(self) {
            return "Ayer"
        }
        return formatted(date: .abbreviated, time: .omitted)
    }
}
