import SwiftUI

@main
struct ClosetSocialApp: App {
    @State private var session = AppSession()
    private let dependencies: AppDependencies

    init() {
        // Backend en local. Cambia esta URL cuando despliegues.
        let baseURL = URL(string: "http://127.0.0.1:8080")!
        self.dependencies = AppDependencies.live(baseURL: baseURL)
    }

    var body: some Scene {
        WindowGroup {
            RootView(session: session, dependencies: dependencies)
        }
    }
}
