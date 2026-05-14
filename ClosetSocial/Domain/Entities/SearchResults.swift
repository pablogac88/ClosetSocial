import Foundation

public struct SearchResults: Sendable, Equatable {
    public let users: [User]
    public let garments: [Garment]
    public let outfits: [Outfit]

    public init(users: [User], garments: [Garment], outfits: [Outfit]) {
        self.users = users
        self.garments = garments
        self.outfits = outfits
    }

    public var isEmpty: Bool {
        users.isEmpty && garments.isEmpty && outfits.isEmpty
    }
}
