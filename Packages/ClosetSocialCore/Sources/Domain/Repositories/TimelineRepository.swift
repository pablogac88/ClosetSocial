import Foundation

public protocol TimelineRepository: Sendable {
    func fetchTimeline(token: String) async throws -> [FeedPost]
}
