import Foundation

enum ClosetSocialEndpoint {
    static let login = "auth/login"
    static let register = "auth/register"
    static let timeline = "api/timeline"
    static let closet = "api/closet"
    static let outfits = "api/outfits"
    static let posts = "api/posts"
    static let profile = "api/profile"

    static func postLike(id: UUID) -> String { "api/posts/\(id)/like" }
    static func postComments(id: UUID) -> String { "api/posts/\(id)/comments" }
    static func userProfile(id: UUID) -> String { "api/users/\(id)/profile" }
}
