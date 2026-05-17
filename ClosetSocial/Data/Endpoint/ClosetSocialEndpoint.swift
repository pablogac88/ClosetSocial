import Foundation

enum ClosetSocialEndpoint {
    static let login = "auth/login"
    static let register = "auth/register"
    static let timeline = "api/timeline"
    static let discover = "api/discover"
    static let closet = "api/closet"
    static let outfits = "api/outfits"
    static let posts = "api/posts"
    static let profile = "api/profile"
    static let search = "api/search"
    static let notifications = "api/notifications"
    static let notificationsReadAll = "api/notifications/read-all"

    static func garment(id: UUID) -> String { "api/garments/\(id)" }
    static func outfit(id: UUID) -> String { "api/outfits/\(id)" }
    static func postLike(id: UUID) -> String { "api/posts/\(id)/like" }
    static func postComments(id: UUID) -> String { "api/posts/\(id)/comments" }
    static func userProfile(id: UUID) -> String { "api/users/\(id)/profile" }
    static func followUser(id: UUID) -> String { "api/users/\(id)/follow" }
    static func userFollowers(id: UUID) -> String { "api/users/\(id)/followers" }
    static func userFollowing(id: UUID) -> String { "api/users/\(id)/following" }
    static func notificationRead(id: UUID) -> String { "api/notifications/\(id)/read" }
    static let uploadImage = "api/uploads/image"
}
