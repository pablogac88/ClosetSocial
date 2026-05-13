import Foundation

public protocol OutfitsRepository: Sendable {
    func fetchOutfits(token: String) async throws -> [Outfit]
    func createOutfit(token: String, request: CreateOutfitRequest) async throws -> Outfit
}

public struct CreateOutfitRequest: Sendable {
    public let title: String?
    public let note: String?
    public let garmentIDs: [UUID]

    public init(title: String?, note: String?, garmentIDs: [UUID]) {
        self.title = title
        self.note = note
        self.garmentIDs = garmentIDs
    }
}
