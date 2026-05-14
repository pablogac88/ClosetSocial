import Foundation

public struct NewGarment: Codable, Sendable, Equatable {
    public let name: String
    public let brand: String?
    public let type: GarmentType
    public let color: String
    public let imageURL: URL?

    public init(name: String, brand: String?, type: GarmentType, color: String, imageURL: URL?) {
        self.name = name
        self.brand = brand
        self.type = type
        self.color = color
        self.imageURL = imageURL
    }
}

public protocol ClosetRepository: Sendable {
    func fetchCloset(token: String) async throws -> [Garment]
    func createGarment(token: String, garment: NewGarment) async throws -> Garment
    func deleteGarment(token: String, id: UUID) async throws
}
