import SwiftUI
import Domain
import DesignSystem
import TimelineFeature
import ClosetFeature
import OutfitsFeature
import ProfileFeature

struct MainTabView: View {
    let session: AppSession
    let dependencies: AppDependencies

    @State private var timelineViewModel: TimelineViewModel
    @State private var closetViewModel: ClosetViewModel
    @State private var outfitsViewModel: OutfitsViewModel
    @State private var profileViewModel: ProfileViewModel

    init(session: AppSession, dependencies: AppDependencies) {
        self.session = session
        self.dependencies = dependencies

        let tokenProvider: @MainActor () -> String? = { [session] in
            session.currentToken
        }

        let timeline = TimelineViewModel(
            repository: dependencies.timelineRepository,
            tokenProvider: tokenProvider
        )
        let outfits = OutfitsViewModel(
            repository: dependencies.outfitsRepository,
            tokenProvider: tokenProvider
        )
        let profile = ProfileViewModel(
            repository: dependencies.profileRepository,
            tokenProvider: tokenProvider,
            onLogout: { [session] in session.signOut() }
        )
        let closet = ClosetViewModel(
            repository: dependencies.closetRepository,
            addGarmentUseCase: dependencies.addGarmentUseCase,
            tokenProvider: tokenProvider
        ) { result in
            timeline.replace(with: result.updatedTimeline)
            profile.replace(with: result.updatedProfile)
        }

        self._timelineViewModel = State(initialValue: timeline)
        self._closetViewModel = State(initialValue: closet)
        self._outfitsViewModel = State(initialValue: outfits)
        self._profileViewModel = State(initialValue: profile)
    }

    var body: some View {
        TabView {
            NavigationStack {
                TimelineView(viewModel: timelineViewModel)
            }
            .tabItem { Label("Timeline", systemImage: "sparkles.rectangle.stack") }

            NavigationStack {
                ClosetView(viewModel: closetViewModel)
            }
            .tabItem { Label("Armario", systemImage: "hanger") }

            NavigationStack {
                OutfitsView(viewModel: outfitsViewModel)
            }
            .tabItem { Label("Outfits", systemImage: "square.grid.2x2") }

            NavigationStack {
                ProfileView(viewModel: profileViewModel)
            }
            .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
        }
    }
}
