import Foundation

struct GarmentSubtypeResponseDTO: Codable, Sendable {
    let id: UUID
    let name: String
}

struct GarmentCategoryResponseDTO: Codable, Sendable {
    let id: UUID
    let name: String
    let subtypes: [GarmentSubtypeResponseDTO]
}

struct BrandResponseDTO: Codable, Sendable {
    let id: UUID
    let name: String
}

extension GarmentCategoryResponseDTO {
    func toDomain() -> GarmentCategory {
        GarmentCategory(
            id: id,
            name: name,
            subtypes: subtypes.map { GarmentType($0.name) }
        )
    }
}

extension BrandResponseDTO {
    func toDomain() -> Brand {
        Brand(id: id, name: name)
    }
}
