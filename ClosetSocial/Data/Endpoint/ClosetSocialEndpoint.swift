import Foundation

enum ClosetSocialEndpoint {
    static let login = "auth/login"
    static let register = "auth/register"
    static let timeline = "api/timeline"
    static let timelineForYou = "api/timeline/for-you"
    static let discover = "api/discover"
    static let closet = "api/closet"
    static let catalogGarmentTypes = "api/catalog/garment-types"
    static let catalogGarmentCategories = "api/catalog/garment-categories"
    static let catalogBrands = "api/catalog/brands"
    static let outfits = "api/outfits"
    static let posts = "api/posts"
    static let profile = "api/profile"
    static let search = "api/search"
    static let notifications = "api/notifications"
    static let notificationsReadAll = "api/notifications/read-all"

    static func garment(id: UUID) -> String { "api/garments/\(id)" }
    static let savedOutfits = "api/outfits/saved"
    static func outfit(id: UUID) -> String { "api/outfits/\(id)" }
    static func outfitSave(id: UUID) -> String { "api/outfits/\(id)/save" }
    static func postLike(id: UUID) -> String { "api/posts/\(id)/like" }
    static func postSave(id: UUID) -> String { "api/posts/\(id)/save" }
    static func postComments(id: UUID) -> String { "api/posts/\(id)/comments" }
    static func userProfile(id: UUID) -> String { "api/users/\(id)/profile" }
    static func followUser(id: UUID) -> String { "api/users/\(id)/follow" }
    static func userFollowers(id: UUID) -> String { "api/users/\(id)/followers" }
    static func userFollowing(id: UUID) -> String { "api/users/\(id)/following" }
    static func notificationRead(id: UUID) -> String { "api/notifications/\(id)/read" }
    static let uploadImage = "api/uploads/image"
}
