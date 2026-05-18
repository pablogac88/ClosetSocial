import Foundation
import Observation

public enum ChatMessagesState: Sendable {
    case idle
    case loading
    case content([ChatMessage])
    case error(String)
}

@MainActor
@Observable
public final class ChatDetailViewModel {
    public typealias TokenProvider = @MainActor () -> String?
    public typealias PreviewUpdater = @MainActor (ConversationPreview) -> Void
    public typealias ConversationsRefresher = @MainActor () async -> Void

    public let conversation: Conversation
    public let currentUserID: UUID

    public private(set) var state: ChatMessagesState = .idle
    public private(set) var isSending = false
    public private(set) var errorMessage: String?
    public var draft: String = ""

    private let repository: any ChatRepository
    private let socketClient: ChatWebSocketClient
    private let tokenProvider: TokenProvider
    private let applyConversationPreview: PreviewUpdater
    private let refreshConversations: ConversationsRefresher
    private var didStart = false
    private var streamTask: Task<Void, Never>?

    public init(
        conversation: Conversation,
        currentUserID: UUID,
        repository: any ChatRepository,
        socketClient: ChatWebSocketClient,
        tokenProvider: @escaping TokenProvider,
        applyConversationPreview: @escaping PreviewUpdater,
        refreshConversations: @escaping ConversationsRefresher
    ) {
        self.conversation = conversation
        self.currentUserID = currentUserID
        self.repository = repository
        self.socketClient = socketClient
        self.tokenProvider = tokenProvider
        self.applyConversationPreview = applyConversationPreview
        self.refreshConversations = refreshConversations
    }

    public var messages: [ChatMessage] {
        switch state {
        case let .content(items):
            return items
        case .idle, .loading, .error:
            return []
        }
    }

    public func start() async {
        guard !didStart else { return }
        didStart = true
        observeSocketEvents()
        await load()
        await markRead()
    }

    public func load(showLoadingState: Bool = true) async {
        guard let token = tokenProvider() else {
            state = .error(DomainError.unauthenticated.userMessage)
            return
        }

        let previousState = state
        if showLoadingState {
            state = .loading
        }

        do {
            let fetchedMessages = try await repository.fetchMessages(conversationID: conversation.id, token: token)
            state = .content(fetchedMessages)
        } catch {
            if !showLoadingState {
                state = previousState
            } else {
                state = .error(error.userMessage)
            }
        }
    }

    public func refresh() async {
        await load(showLoadingState: false)
        await markRead()
    }

    public func stop() {
        streamTask?.cancel()
        streamTask = nil
        didStart = false
    }

    public func sendMessage() async {
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !isSending, let token = tokenProvider() else { return }

        isSending = true
        errorMessage = nil

        do {
            let message = try await repository.sendMessage(
                conversationID: conversation.id,
                body: body,
                token: token
            )
            draft = ""
            upsert(message)
            await refreshConversations()
        } catch {
            errorMessage = error.userMessage
        }

        isSending = false
    }

    public func isMine(_ message: ChatMessage) -> Bool {
        message.sender.id == currentUserID
    }

    private func observeSocketEvents() {
        guard streamTask == nil else { return }

        let stream = socketClient.stream()
        streamTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await event in stream {
                guard !Task.isCancelled else { break }
                switch event {
                case .connected:
                    break
                case let .messageCreated(conversationPreview, message):
                    guard message.conversationID == self.conversation.id else { continue }
                    self.upsert(message)
                    self.applyConversationPreview(conversationPreview)
                    if message.sender.id != self.currentUserID {
                        await self.markRead()
                    }
                case let .conversationUpdated(conversationPreview):
                    guard conversationPreview.id == self.conversation.id else { continue }
                    self.applyConversationPreview(conversationPreview)
                }
            }
        }
    }

    private func upsert(_ message: ChatMessage) {
        switch state {
        case let .content(items):
            var updated = items
            if let index = updated.firstIndex(where: { $0.id == message.id }) {
                updated[index] = message
            } else {
                updated.append(message)
            }
            updated.sort { $0.createdAt < $1.createdAt }
            state = .content(updated)
        case .idle, .loading, .error:
            state = .content([message])
        }
    }

    private func markRead() async {
        guard let token = tokenProvider() else { return }

        do {
            let preview = try await repository.markRead(
                conversationID: conversation.id,
                token: token
            )
            applyConversationPreview(preview)
        } catch {
            // No tumbamos la conversación por fallar el markRead.
        }
    }
}
