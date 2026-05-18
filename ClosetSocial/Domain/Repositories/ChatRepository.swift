import Foundation

public protocol ChatRepository: Sendable {
    func createOrGetConversation(userID: UUID, token: String) async throws -> Conversation
    func fetchConversations(token: String) async throws -> [ConversationPreview]
    func fetchMessages(conversationID: UUID, token: String) async throws -> [ChatMessage]
    func sendMessage(conversationID: UUID, body: String, token: String) async throws -> ChatMessage
    func markRead(conversationID: UUID, token: String) async throws -> ConversationPreview
}
