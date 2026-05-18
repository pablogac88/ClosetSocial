import SwiftUI

public struct ChatDetailView: View {
    @State private var viewModel: ChatDetailViewModel
    @FocusState private var isComposerFocused: Bool

    public init(viewModel: ChatDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ScrollViewReader { proxy in
            content
                .background(DSColor.background.ignoresSafeArea())
                .navigationTitle(viewModel.conversation.otherParticipant.displayName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        AvatarBubble(
                            displayName: viewModel.conversation.otherParticipant.displayName,
                            avatarURL: viewModel.conversation.otherParticipant.avatarURL,
                            size: 34,
                            fillColor: DSColor.warmFill,
                            textColor: DSColor.secondaryText
                        )
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    composer
                }
                .task { await viewModel.start() }
                .onDisappear { viewModel.stop() }
                .onChange(of: viewModel.messages.last?.id) { _, newValue in
                    guard let newValue else { return }
                    withAnimation(.easeOut(duration: 0.22)) {
                        proxy.scrollTo(newValue, anchor: .bottom)
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            ContentUnavailableView(
                "No hemos podido cargar este chat",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case .content:
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        VStack(spacing: 12) {
                            AvatarBubble(
                                displayName: viewModel.conversation.otherParticipant.displayName,
                                avatarURL: viewModel.conversation.otherParticipant.avatarURL,
                                size: 72,
                                fillColor: DSColor.warmFill,
                                textColor: DSColor.secondaryText
                            )

                            Text("Empieza la conversación")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundStyle(DSColor.primaryText)

                            Text("Tu historial se guardará y seguirá aquí aunque cierres la app.")
                                .font(.system(.subheadline, design: .rounded, weight: .regular))
                                .foregroundStyle(DSColor.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 28)
                        .padding(.top, 64)
                    } else {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message, isMine: viewModel.isMine(message))
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 16)
            }
            .refreshable { await viewModel.refresh() }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(DSColor.destructive)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Escribe un mensaje", text: $viewModel.draft, axis: .vertical)
                    .lineLimit(1...5)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .focused($isComposerFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(DSColor.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(DSColor.border, lineWidth: 1)
                    )
                    .foregroundStyle(DSColor.primaryText)

                Button {
                    Task { await viewModel.sendMessage() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? DSColor.surfaceElevated
                                : DSColor.actionPrimaryBackground)
                            .frame(width: 46, height: 46)

                        if viewModel.isSending {
                            ProgressView()
                                .tint(DSColor.actionPrimaryForeground)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(
                                    viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? DSColor.tertiaryText
                                        : DSColor.actionPrimaryForeground
                                )
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
    }
}

private struct ChatBubble: View {
    let message: ChatMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 52) }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 5) {
                Text(message.body)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(isMine ? DSColor.actionPrimaryForeground : DSColor.primaryText)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(isMine ? DSColor.actionPrimaryBackground : DSColor.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isMine ? Color.clear : DSColor.border, lineWidth: 1)
                    )

                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(DSColor.tertiaryText)
                    .padding(.horizontal, 4)
            }

            if !isMine { Spacer(minLength: 52) }
        }
    }
}
