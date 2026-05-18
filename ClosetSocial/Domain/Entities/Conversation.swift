import Foundation

public struct Conversation: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: UUID
    public let otherParticipant: User
    public let createdAt: Date?
    public let updatedAt: Date?
    public let lastMessageAt: Date?

    public init(
        id: UUID,
        otherParticipant: User,
        createdAt: Date?,
        updatedAt: Date?,
        lastMessageAt: Date?
    ) {
        self.id = id
        self.otherParticipant = otherParticipant
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastMessageAt = lastMessageAt
    }
}

public struct ConversationPreview: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: UUID
    public let otherParticipant: User
    public let lastMessage: String?
    public let lastMessageSenderID: UUID?
    public let lastMessageAt: Date?
    public let unreadCount: Int

    public init(
        id: UUID,
        otherParticipant: User,
        lastMessage: String?,
        lastMessageSenderID: UUID?,
        lastMessageAt: Date?,
        unreadCount: Int
    ) {
        self.id = id
        self.otherParticipant = otherParticipant
        self.lastMessage = lastMessage
        self.lastMessageSenderID = lastMessageSenderID
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
    }

    public var hasUnread: Bool {
        unreadCount > 0
    }

    public var asConversation: Conversation {
        Conversation(
            id: id,
            otherParticipant: otherParticipant,
            createdAt: nil,
            updatedAt: nil,
            lastMessageAt: lastMessageAt
        )
    }
}

public struct ChatMessage: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: UUID
    public let conversationID: UUID
    public let sender: User
    public let body: String
    public let createdAt: Date
    public let editedAt: Date?
    public let deletedAt: Date?

    public init(
        id: UUID,
        conversationID: UUID,
        sender: User,
        body: String,
        createdAt: Date,
        editedAt: Date?,
        deletedAt: Date?
    ) {
        self.id = id
        self.conversationID = conversationID
        self.sender = sender
        self.body = body
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.deletedAt = deletedAt
    }
}

public enum ChatSocketEvent: Sendable, Equatable, Hashable {
    case connected
    case messageCreated(conversation: ConversationPreview, message: ChatMessage)
    case conversationUpdated(ConversationPreview)
}
