import Foundation

public protocol OutfitsRepository: Sendable {
    func fetchOutfits(token: String) async throws -> [Outfit]
}
