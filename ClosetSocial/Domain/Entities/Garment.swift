import Foundation

public enum GarmentType: String, Codable, Sendable, Equatable, CaseIterable, Identifiable {
    case tShirt = "Camiseta"
    case shirt = "Camisa"
    case blazer = "Blazer"
    case jacket = "Chaqueta"
    case coat = "Abrigo"
    case trousers = "Pantalón"
    case top = "Top"
    case dress = "Vestido"
    case shoes = "Zapatos"
    case accessory = "Accesorio"
    case other = "Otro"

    public var id: String { rawValue }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = GarmentType(rawValue: rawValue) ?? .other
    }
}

public struct Garment: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let brand: String?
    public let type: GarmentType
    public let color: String
    public let imageURL: URL?
    public let createdAt: Date

    public init(
        id: UUID,
        name: String,
        brand: String?,
        type: GarmentType,
        color: String,
        imageURL: URL?,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.type = type
        self.color = color
        self.imageURL = imageURL
        self.createdAt = createdAt
    }
}
