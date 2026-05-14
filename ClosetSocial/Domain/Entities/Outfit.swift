import Foundation

public struct Outfit: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let title: String?
    public let note: String?
    public let garments: [Garment]
    public let layout: OutfitComposerLayout?
    public let createdAt: Date

    public init(
        id: UUID,
        title: String?,
        note: String?,
        garments: [Garment],
        layout: OutfitComposerLayout? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.garments = garments
        self.layout = layout
        self.createdAt = createdAt
    }
}
