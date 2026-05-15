import SwiftUI

@main
struct ClosetSocialApp: App {
    @State private var session = AppSession()
    private let dependencies: AppDependencies

    init() {
        let rawURL = Bundle.main.infoDictionary?["BASE_URL"] as? String ?? "http://127.0.0.1:8080"
        let baseURL = URL(string: rawURL)!
        self.dependencies = AppDependencies.live(baseURL: baseURL)
    }

    var body: some Scene {
        WindowGroup {
            RootView(session: session, dependencies: dependencies)
        }
    }
}
