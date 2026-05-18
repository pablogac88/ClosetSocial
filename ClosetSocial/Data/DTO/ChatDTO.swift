import Foundation

struct ConversationDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let otherParticipant: UserDTO
    let createdAt: Date?
    let updatedAt: Date?
    let lastMessageAt: Date?
}

struct ConversationPreviewDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let otherParticipant: UserDTO
    let lastMessage: String?
    let lastMessageSenderID: UUID?
    let lastMessageAt: Date?
    let unreadCount: Int
}

struct ChatMessageDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let conversationID: UUID
    let sender: UserDTO
    let body: String
    let createdAt: Date
    let editedAt: Date?
    let deletedAt: Date?
}

struct SendMessageRequestDTO: Codable, Sendable, Equatable {
    let body: String
}

enum ChatSocketEventTypeDTO: String, Codable, Sendable, Equatable {
    case connected = "connected"
    case messageCreated = "message.created"
    case conversationUpdated = "conversation.updated"
}

struct ChatSocketEventDTO: Codable, Sendable, Equatable {
    let type: ChatSocketEventTypeDTO
    let conversation: ConversationPreviewDTO?
    let message: ChatMessageDTO?
}

extension ConversationDTO {
    func toDomain() -> Conversation {
        Conversation(
            id: id,
            otherParticipant: otherParticipant.toDomain(),
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastMessageAt: lastMessageAt
        )
    }
}

extension ConversationPreviewDTO {
    func toDomain() -> ConversationPreview {
        ConversationPreview(
            id: id,
            otherParticipant: otherParticipant.toDomain(),
            lastMessage: lastMessage,
            lastMessageSenderID: lastMessageSenderID,
            lastMessageAt: lastMessageAt,
            unreadCount: unreadCount
        )
    }
}

extension ChatMessageDTO {
    func toDomain() -> ChatMessage {
        ChatMessage(
            id: id,
            conversationID: conversationID,
            sender: sender.toDomain(),
            body: body,
            createdAt: createdAt,
            editedAt: editedAt,
            deletedAt: deletedAt
        )
    }
}

extension ChatSocketEventDTO {
    func toDomain() -> ChatSocketEvent? {
        switch type {
        case .connected:
            return .connected
        case .messageCreated:
            guard let conversation, let message else { return nil }
            return .messageCreated(
                conversation: conversation.toDomain(),
                message: message.toDomain()
            )
        case .conversationUpdated:
            guard let conversation else { return nil }
            return .conversationUpdated(conversation.toDomain())
        }
    }
}
