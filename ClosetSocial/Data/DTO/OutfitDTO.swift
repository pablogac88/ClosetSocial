import Foundation

struct OutfitDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let title: String?
    let note: String?
    let garments: [GarmentDTO]?
    let garmentIDs: [UUID]?
    let garmentNames: [String]?
    let createdAt: Date
}

struct OutfitsResponseDTO: Codable, Sendable, Equatable {
    let items: [OutfitDTO]
}
