import Foundation

struct FeedPostDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let author: UserDTO
    let kind: String
    let caption: String
    let outfit: OutfitDTO?
    let garment: GarmentDTO?
    let garmentName: String?
    let imageURL: String?
    let imageURLs: [String]?
    let createdAt: Date
}

struct TimelineResponseDTO: Codable, Sendable, Equatable {
    let items: [FeedPostDTO]
}
