import Foundation

struct ExploreUserSummaryDTO: Codable, Sendable, Equatable, Identifiable {
    let user: UserDTO
    let closetCount: Int
    let outfitCount: Int
    let postsCount: Int
    let followerCount: Int
    let followingCount: Int
    let isFollowing: Bool

    var id: UUID { user.id }
}

struct ExploreGarmentSummaryDTO: Codable, Sendable, Equatable, Identifiable {
    let garment: GarmentDTO
    let owner: UserDTO?

    var id: UUID { garment.id }
}

struct ExploreOutfitSummaryDTO: Codable, Sendable, Equatable, Identifiable {
    let outfit: OutfitDTO
    let author: UserDTO

    var id: UUID { outfit.id }
}

struct DiscoverUsersResponseDTO: Codable, Sendable, Equatable {
    let items: [ExploreUserSummaryDTO]
}

struct DiscoverGarmentsResponseDTO: Codable, Sendable, Equatable {
    let items: [ExploreGarmentSummaryDTO]
}

struct DiscoverOutfitsResponseDTO: Codable, Sendable, Equatable {
    let items: [ExploreOutfitSummaryDTO]
}

struct SearchResultsDTO: Codable, Sendable, Equatable {
    let users: [ExploreUserSummaryDTO]
    let garments: [ExploreGarmentSummaryDTO]
    let outfits: [ExploreOutfitSummaryDTO]
}
