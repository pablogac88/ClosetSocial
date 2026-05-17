import Foundation

public struct GarmentCategory: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let subtypes: [GarmentType]

    public init(id: UUID, name: String, subtypes: [GarmentType]) {
        self.id = id
        self.name = name
        self.subtypes = subtypes
    }

    public static let defaultCategories: [GarmentCategory] = GarmentType.defaultOptions.map {
        GarmentCategory(id: UUID(), name: $0.name, subtypes: [$0])
    }
}

public struct Brand: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}
