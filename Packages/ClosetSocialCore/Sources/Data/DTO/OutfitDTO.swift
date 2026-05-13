import Foundation

struct OutfitDTO: Codable, Sendable {
    let id: UUID
    let title: String
    let note: String
    let garmentNames: [String]
    let createdAt: Date
}

struct OutfitsResponseDTO: Codable, Sendable {
    let items: [OutfitDTO]
}
