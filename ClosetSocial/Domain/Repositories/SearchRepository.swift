import Foundation

public protocol SearchRepository: Sendable {
    func search(token: String, query: String) async throws -> SearchResults
}

public protocol ExploreRepository: Sendable {
    func fetchDiscoverOutfits(token: String, limit: Int) async throws -> [ExploreOutfitItem]
    func fetchDiscoverGarments(token: String, limit: Int) async throws -> [ExploreGarmentItem]
    func fetchDiscoverUsers(token: String, limit: Int) async throws -> [ExploreUserItem]
    func search(token: String, query: String) async throws -> ExploreSearchResults
}
