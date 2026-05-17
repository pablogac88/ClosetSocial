import Foundation

struct GarmentDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let brand: String?
    let type: GarmentType
    let color: String
    let imageURL: String?
    let createdAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case type = "category"
        case color
        case imageURL
        case createdAt
    }
}

struct ClosetResponseDTO: Codable, Sendable, Equatable {
    let items: [GarmentDTO]
}

struct CreateGarmentRequestDTO: Codable, Sendable, Equatable {
    let name: String
    let brand: String?
    let type: GarmentType
    let color: String
    let imageURL: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case brand
        case type = "category"
        case color
        case imageURL
    }
}

struct GarmentTypeOptionDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let name: String
}
