import SwiftUI

struct MainTabView: View {
    let session: AppSession
    let dependencies: AppDependencies

    @State private var timelineViewModel: TimelineViewModel
    @State private var exploreViewModel: ExploreViewModel
    @State private var closetViewModel: ClosetViewModel
    @State private var outfitsViewModel: OutfitsViewModel
    @State private var profileViewModel: ProfileViewModel

    private let tokenProvider: @MainActor () -> String?

    init(session: AppSession, dependencies: AppDependencies) {
        self.session = session
        self.dependencies = dependencies

        let tokenProvider: @MainActor () -> String? = { [session] in
            session.currentToken
        }
        self.tokenProvider = tokenProvider

        let timeline = TimelineViewModel(
            repository: dependencies.timelineRepository,
            closetRepository: dependencies.closetRepository,
            outfitsRepository: dependencies.outfitsRepository,
            tokenProvider: tokenProvider
        )
        let profile = ProfileViewModel(
            repository: dependencies.profileRepository,
            timelineRepository: dependencies.timelineRepository,
            closetRepository: dependencies.closetRepository,
            outfitsRepository: dependencies.outfitsRepository,
            notificationRepository: dependencies.notificationRepository,
            tokenProvider: tokenProvider,
            onLogout: { [session] in session.signOut() }
        )
        let explore = ExploreViewModel(
            editorialRepository: dependencies.timelineRepository,
            searchRepository: dependencies.searchRepository,
            tokenProvider: tokenProvider
        )
        let outfits = OutfitsViewModel(
            repository: dependencies.outfitsRepository,
            closetRepository: dependencies.closetRepository,
            timelineRepository: dependencies.timelineRepository,
            tokenProvider: tokenProvider,
            onOutfitDeleted: {
                Task {
                    await timeline.load()
                    await explore.load()
                    await profile.load()
                }
            }
        )
        let closet = ClosetViewModel(
            repository: dependencies.closetRepository,
            catalogRepository: dependencies.catalogRepository,
            addGarmentUseCase: dependencies.addGarmentUseCase,
            uploadRepository: dependencies.uploadRepository,
            tokenProvider: tokenProvider
        ) { result in
            timeline.replace(with: result.updatedTimeline)
            explore.replace(with: result.updatedTimeline)
            profile.replace(with: result.updatedProfile)
        } onGarmentDeleted: {
            Task {
                await timeline.load()
                await explore.load()
                await profile.load()
            }
        }

        self._timelineViewModel = State(initialValue: timeline)
        self._exploreViewModel = State(initialValue: explore)
        self._closetViewModel = State(initialValue: closet)
        self._outfitsViewModel = State(initialValue: outfits)
        self._profileViewModel = State(initialValue: profile)
    }

    @MainActor
    private func makePublicProfileViewModel(for userID: UUID) -> PublicProfileViewModel {
        PublicProfileViewModel(
            userID: userID,
            currentUserID: session.currentUser?.id,
            repository: dependencies.profileRepository,
            tokenProvider: tokenProvider
        )
    }

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TimelineView(
                    viewModel: timelineViewModel,
                    makePublicProfileViewModel: makePublicProfileViewModel(for:),
                    onAddGarmentTap: { selectedTab = 2 }
                )
            }
            .tag(0)
            .tabItem { Label("Timeline", systemImage: "sparkles.rectangle.stack") }

            NavigationStack {
                ExploreView(
                    viewModel: exploreViewModel,
                    makePublicProfileViewModel: makePublicProfileViewModel(for:)
                )
            }
            .tag(1)
            .tabItem { Label("Explore", systemImage: "square.grid.3x3.square") }

            NavigationStack {
                ClosetView(
                    viewModel: closetViewModel,
                    findRelatedOutfits: { garment in
                        if case .content(let outfits) = outfitsViewModel.state {
                            return outfits.filter { outfit in
                                outfit.garments.contains { $0.id == garment.id }
                            }
                        }
                        return []
                    }
                )
            }
            .tag(2)
            .tabItem { Label("Armario", systemImage: "hanger") }

            NavigationStack {
                OutfitsView(viewModel: outfitsViewModel)
            }
            .tag(3)
            .tabItem { Label("Outfits", systemImage: "square.grid.2x2") }

            NavigationStack {
                ProfileView(
                    viewModel: profileViewModel,
                    makePublicProfileViewModel: makePublicProfileViewModel(for:),
                    uploadRepository: dependencies.uploadRepository,
                    tokenProvider: tokenProvider
                )
            }
            .tag(4)
            .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
        }
    }
}
