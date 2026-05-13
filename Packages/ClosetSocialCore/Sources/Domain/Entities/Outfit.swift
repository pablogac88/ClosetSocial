import Foundation

public struct Outfit: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let title: String
    public let note: String
    public let garmentNames: [String]
    public let createdAt: Date

    public init(
        id: UUID,
        title: String,
        note: String,
        garmentNames: [String],
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.garmentNames = garmentNames
        self.createdAt = createdAt
    }
}
