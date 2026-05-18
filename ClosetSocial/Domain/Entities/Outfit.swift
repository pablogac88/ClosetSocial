import Foundation

public struct Outfit: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: UUID
    public let title: String?
    public let note: String?
    public let garments: [Garment]
    public let layout: OutfitComposerLayout?
    public let coverImageURL: URL?
    public let isSavedByCurrentUser: Bool
    public let createdAt: Date

    public init(
        id: UUID,
        title: String?,
        note: String?,
        garments: [Garment],
        layout: OutfitComposerLayout? = nil,
        coverImageURL: URL? = nil,
        isSavedByCurrentUser: Bool = false,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.garments = garments
        self.layout = layout
        self.coverImageURL = coverImageURL
        self.isSavedByCurrentUser = isSavedByCurrentUser
        self.createdAt = createdAt
    }

    func togglingBookmark() -> Outfit {
        Outfit(
            id: id, title: title, note: note, garments: garments,
            layout: layout, coverImageURL: coverImageURL,
            isSavedByCurrentUser: !isSavedByCurrentUser,
            createdAt: createdAt
        )
    }
}
