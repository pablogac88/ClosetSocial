import Foundation

public protocol SearchRepository: Sendable {
    func search(token: String, query: String) async throws -> SearchResults
}
