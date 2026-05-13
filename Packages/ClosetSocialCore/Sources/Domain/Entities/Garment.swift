import Foundation

public struct Garment: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let brand: String
    public let category: String
    public let color: String

    public init(
        id: UUID,
        name: String,
        brand: String,
        category: String,
        color: String
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.color = color
    }
}
