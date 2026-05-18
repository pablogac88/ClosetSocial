import Foundation

struct OutfitDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let title: String?
    let note: String?
    let garments: [GarmentDTO]?
    let garmentIDs: [UUID]?
    let garmentNames: [String]?
    let layoutJSON: String?
    let coverImageURL: String?
    let isSavedByCurrentUser: Bool?
    let createdAt: Date
}

struct OutfitsResponseDTO: Codable, Sendable, Equatable {
    let items: [OutfitDTO]
}

struct CreateOutfitRequestDTO: Encodable, Sendable {
    let title: String?
    let note: String?
    let garmentIDs: [UUID]
    let layoutJSON: String?
    let coverImageURL: String?
}

extension CreateOutfitRequest {
    func toDTO() -> CreateOutfitRequestDTO {
        let encodedLayout: String? = layout.flatMap { l in
            guard let data = try? JSONEncoder().encode(l) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        return CreateOutfitRequestDTO(
            title: title,
            note: note,
            garmentIDs: garmentIDs,
            layoutJSON: encodedLayout,
            coverImageURL: coverImageURL
        )
    }
}
