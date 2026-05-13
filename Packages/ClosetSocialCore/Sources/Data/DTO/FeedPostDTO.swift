import Foundation

struct FeedPostDTO: Codable, Sendable {
    let id: UUID
    let author: UserDTO
    let kind: String
    let caption: String
    let garmentName: String?
    let imageURL: String?
    let createdAt: Date
}

struct TimelineResponseDTO: Codable, Sendable {
    let items: [FeedPostDTO]
}
