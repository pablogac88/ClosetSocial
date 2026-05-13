import Foundation

struct GarmentDTO: Codable, Sendable {
    let id: UUID
    let name: String
    let brand: String
    let category: String
    let color: String
}

struct ClosetResponseDTO: Codable, Sendable {
    let items: [GarmentDTO]
}

struct CreateGarmentRequestDTO: Codable, Sendable {
    let name: String
    let brand: String
    let category: String
    let color: String
}
