import Foundation
import Observation

public enum ConversationsState: Sendable {
    case idle
    case loading
    case content([ConversationPreview])
    case empty
    case error(String)
}

@MainActor
@Observable
public final class ConversationsViewModel {
    public typealias TokenProvider = @MainActor () -> String?

    public private(set) var state: ConversationsState = .idle

    private let repository: any ChatRepository
    private let socketClient: ChatWebSocketClient
    private let tokenProvider: TokenProvider
    private var didStart = false
    private var streamTask: Task<Void, Never>?

    public init(
        repository: any ChatRepository,
        socketClient: ChatWebSocketClient,
        tokenProvider: @escaping TokenProvider
    ) {
        self.repository = repository
        self.socketClient = socketClient
        self.tokenProvider = tokenProvider
    }

    public var unreadCount: Int {
        guard case let .content(items) = state else { return 0 }
        return items.reduce(0) { $0 + $1.unreadCount }
    }

    public func start() async {
        guard !didStart else { return }
        didStart = true
        observeSocketEvents()
        await load()
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
            let conversations = try await repository.fetchConversations(token: token)
            state = conversations.isEmpty ? .empty : .content(conversations)
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
    }

    public func stop() {
        streamTask?.cancel()
        streamTask = nil
        didStart = false
    }

    public func apply(_ preview: ConversationPreview) {
        switch state {
        case let .content(items):
            var updated = items
            if let index = updated.firstIndex(where: { $0.id == preview.id }) {
                updated[index] = preview
            } else {
                updated.insert(preview, at: 0)
            }
            updated.sort { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
            state = updated.isEmpty ? .empty : .content(updated)
        case .empty, .idle, .loading, .error:
            state = .content([preview])
        }
    }

    public func markConversationReadLocally(_ conversationID: UUID) {
        guard case let .content(items) = state,
              let index = items.firstIndex(where: { $0.id == conversationID })
        else { return }

        let current = items[index]
        let updated = ConversationPreview(
            id: current.id,
            otherParticipant: current.otherParticipant,
            lastMessage: current.lastMessage,
            lastMessageSenderID: current.lastMessageSenderID,
            lastMessageAt: current.lastMessageAt,
            unreadCount: 0
        )
        apply(updated)
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
                case let .messageCreated(conversation, _):
                    self.apply(conversation)
                case let .conversationUpdated(conversation):
                    self.apply(conversation)
                }
            }
        }
    }
}
