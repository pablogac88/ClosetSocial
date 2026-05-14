import Foundation

struct SearchResultsDTO: Codable, Sendable, Equatable {
    let users: [UserDTO]
    let garments: [GarmentDTO]
    let outfits: [OutfitDTO]
}
