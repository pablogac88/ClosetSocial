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

struct CreateOutfitRequestDTO: Encodable, Sendable {
    let title: String?
    let note: String?
    let garmentIDs: [UUID]
}

extension CreateOutfitRequest {
    func toDTO() -> CreateOutfitRequestDTO {
        CreateOutfitRequestDTO(title: title, note: note, garmentIDs: garmentIDs)
    }
}
