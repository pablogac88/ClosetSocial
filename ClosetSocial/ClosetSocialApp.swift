import SwiftUI

@main
struct ClosetSocialApp: App {
    @State private var session = AppSession()
    private let dependencies: AppDependencies

    init() {
        let rawURL = Bundle.main.infoDictionary?["BASE_URL"] as? String ?? "http://127.0.0.1:8080"
        let baseURL = URL(string: rawURL)!
        self.dependencies = AppDependencies.live(baseURL: baseURL)

        // 32 MB RAM + 100 MB disk for AsyncImage cache.
        URLCache.shared = URLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 100 * 1024 * 1024
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(session: session, dependencies: dependencies)
        }
    }
}
