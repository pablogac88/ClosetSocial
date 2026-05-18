import Foundation

public struct RemoteChatRepository: ChatRepository {
    private let sender: RemoteRequestSender

    public init(client: any HTTPClient, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.sender = RemoteRequestSender(client: client, encoder: encoder, decoder: decoder)
    }

    public func createOrGetConversation(userID: UUID, token: String) async throws -> Conversation {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.conversation(with: userID),
            method: .post,
            token: token,
            as: ConversationDTO.self
        )
        return dto.toDomain()
    }

    public func fetchConversations(token: String) async throws -> [ConversationPreview] {
        let dtos = try await sender.send(
            path: ClosetSocialEndpoint.conversations,
            method: .get,
            token: token,
            as: [ConversationPreviewDTO].self
        )
        return dtos.map { $0.toDomain() }
    }

    public func fetchMessages(conversationID: UUID, token: String) async throws -> [ChatMessage] {
        let dtos = try await sender.send(
            path: ClosetSocialEndpoint.conversationMessages(id: conversationID),
            method: .get,
            token: token,
            as: [ChatMessageDTO].self
        )
        return dtos.map { $0.toDomain() }
    }

    public func sendMessage(conversationID: UUID, body: String, token: String) async throws -> ChatMessage {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.conversationMessages(id: conversationID),
            method: .post,
            body: SendMessageRequestDTO(body: body),
            token: token,
            as: ChatMessageDTO.self
        )
        return dto.toDomain()
    }

    public func markRead(conversationID: UUID, token: String) async throws -> ConversationPreview {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.conversationRead(id: conversationID),
            method: .patch,
            token: token,
            as: ConversationPreviewDTO.self
        )
        return dto.toDomain()
    }
}
