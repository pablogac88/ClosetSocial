import Foundation

public struct NewGarment: Sendable, Hashable {
    public let name: String
    public let brand: String
    public let category: String
    public let color: String

    public init(name: String, brand: String, category: String, color: String) {
        self.name = name
        self.brand = brand
        self.category = category
        self.color = color
    }
}

public protocol ClosetRepository: Sendable {
    func fetchCloset(token: String) async throws -> [Garment]
    func createGarment(token: String, garment: NewGarment) async throws -> Garment
}
