import Foundation

public struct GarmentType: Codable, Sendable, Equatable, Hashable, Identifiable, CaseIterable {
    public enum Kind: Sendable, Hashable {
        case tShirt
        case shirt
        case blazer
        case jacket
        case coat
        case trousers
        case top
        case dress
        case shoes
        case accessory
        case other

        init(name: String) {
            switch name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            {
            case "camiseta", "tshirt", "t-shirt":
                self = .tShirt
            case "camisa", "shirt":
                self = .shirt
            case "blazer":
                self = .blazer
            case "chaqueta", "jacket":
                self = .jacket
            case "abrigo", "coat":
                self = .coat
            case "pantalon", "pantalón", "trousers", "pants":
                self = .trousers
            case "top":
                self = .top
            case "vestido", "dress":
                self = .dress
            case "zapatos", "shoes":
                self = .shoes
            case "accesorio", "accessory":
                self = .accessory
            default:
                self = .other
            }
        }
    }

    public static let tShirt = GarmentType("Camiseta")
    public static let shirt = GarmentType("Camisa")
    public static let blazer = GarmentType("Blazer")
    public static let jacket = GarmentType("Chaqueta")
    public static let coat = GarmentType("Abrigo")
    public static let trousers = GarmentType("Pantalón")
    public static let top = GarmentType("Top")
    public static let dress = GarmentType("Vestido")
    public static let shoes = GarmentType("Zapatos")
    public static let accessory = GarmentType("Accesorio")
    public static let other = GarmentType("Otro")

    public static let defaultOptions: [GarmentType] = [
        .tShirt, .shirt, .blazer, .jacket, .coat, .trousers, .top, .dress, .shoes, .accessory, .other
    ]

    public static var allCases: [GarmentType] { defaultOptions }

    public let name: String

    public init(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = trimmed.isEmpty ? "Otro" : trimmed
    }

    public var id: String {
        name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    public var displayName: String { name }
    public var rawValue: String { name }
    public var kind: Kind { Kind(name: name) }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(try container.decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }
}

public struct Garment: Codable, Sendable, Equatable, Hashable, Identifiable {
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
