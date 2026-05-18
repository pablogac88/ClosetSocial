import SwiftUI

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase

    let session: AppSession
    let dependencies: AppDependencies

    @State private var timelineViewModel: TimelineViewModel
    @State private var exploreViewModel: ExploreViewModel
    @State private var closetViewModel: ClosetViewModel
    @State private var outfitsViewModel: OutfitsViewModel
    @State private var profileViewModel: ProfileViewModel
    @State private var conversationsViewModel: ConversationsViewModel

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
            repository: dependencies.exploreRepository,
            outfitsRepository: dependencies.outfitsRepository,
            profileRepository: dependencies.profileRepository,
            tokenProvider: tokenProvider,
            currentUserIDProvider: { [session] in session.currentUser?.id }
        )
        let outfits = OutfitsViewModel(
            repository: dependencies.outfitsRepository,
            closetRepository: dependencies.closetRepository,
            timelineRepository: dependencies.timelineRepository,
            uploadRepository: dependencies.uploadRepository,
            tokenProvider: tokenProvider,
            onOutfitDeleted: {
                Task {
                    await timeline.load()
                    await explore.refreshAllDiscovery()
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
            profile.replace(with: result.updatedProfile)
            Task {
                await explore.refreshAllDiscovery()
            }
        } onGarmentDeleted: {
            Task {
                await timeline.load()
                await explore.refreshAllDiscovery()
                await profile.load()
            }
        }
        let conversations = ConversationsViewModel(
            repository: dependencies.chatRepository,
            socketClient: dependencies.chatSocketClient,
            tokenProvider: tokenProvider
        )

        self._timelineViewModel = State(initialValue: timeline)
        self._exploreViewModel = State(initialValue: explore)
        self._closetViewModel = State(initialValue: closet)
        self._outfitsViewModel = State(initialValue: outfits)
        self._profileViewModel = State(initialValue: profile)
        self._conversationsViewModel = State(initialValue: conversations)
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

    @MainActor
    private func startConversation(with userID: UUID) async throws -> Conversation {
        guard let token = tokenProvider() else {
            throw DomainError.unauthenticated
        }

        let conversation = try await dependencies.chatRepository.createOrGetConversation(
            userID: userID,
            token: token
        )
        await conversationsViewModel.load(showLoadingState: false)
        return conversation
    }

    @MainActor
    private func makeChatDetailViewModel(for conversation: Conversation) -> ChatDetailViewModel {
        ChatDetailViewModel(
            conversation: conversation,
            currentUserID: session.currentUser?.id ?? UUID(),
            repository: dependencies.chatRepository,
            socketClient: dependencies.chatSocketClient,
            tokenProvider: tokenProvider,
            applyConversationPreview: { [conversationsViewModel] preview in
                conversationsViewModel.apply(preview)
            },
            refreshConversations: { [conversationsViewModel] in
                await conversationsViewModel.load(showLoadingState: false)
            }
        )
    }

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TimelineView(
                    viewModel: timelineViewModel,
                    makePublicProfileViewModel: makePublicProfileViewModel(for:),
                    startConversation: startConversation(with:),
                    makeChatDetailViewModel: makeChatDetailViewModel(for:),
                    onAddGarmentTap: { selectedTab = 2 }
                )
            }
            .tag(0)
            .tabItem { Label("Inicio", systemImage: "sparkles.rectangle.stack") }

            NavigationStack {
                ExploreView(
                    viewModel: exploreViewModel,
                    makePublicProfileViewModel: makePublicProfileViewModel(for:),
                    startConversation: startConversation(with:),
                    makeChatDetailViewModel: makeChatDetailViewModel(for:)
                )
            }
            .tag(1)
            .tabItem { Label("Descubrir", systemImage: "square.grid.3x3.square") }

            NavigationStack {
                StyleView(
                    closetViewModel: closetViewModel,
                    outfitsViewModel: outfitsViewModel
                )
            }
            .tag(2)
            .tabItem { Label("Estilo", systemImage: "tshirt") }

            NavigationStack {
                ConversationsView(
                    viewModel: conversationsViewModel,
                    makeChatDetailViewModel: makeChatDetailViewModel(for:)
                )
            }
            .tag(3)
            .tabItem {
                Label("Mensajes", systemImage: "bubble.left.and.bubble.right")
            }
            .badge(conversationsViewModel.unreadCount > 0 ? conversationsViewModel.unreadCount : 0)

            NavigationStack {
                ProfileView(
                    viewModel: profileViewModel,
                    makePublicProfileViewModel: makePublicProfileViewModel(for:),
                    conversationsViewModel: conversationsViewModel,
                    makeChatDetailViewModel: makeChatDetailViewModel(for:),
                    uploadRepository: dependencies.uploadRepository,
                    tokenProvider: tokenProvider
                )
            }
            .tag(4)
            .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
        }
        .task(id: session.currentToken) {
            guard let token = tokenProvider() else { return }
            await conversationsViewModel.start()
            await dependencies.chatSocketClient.connect(token: token)
        }
        .onChange(of: scenePhase) { _, phase in
            Task {
                guard let token = tokenProvider() else { return }
                switch phase {
                case .active:
                    await dependencies.chatSocketClient.connect(token: token)
                    await conversationsViewModel.start()
                case .inactive, .background:
                    await dependencies.chatSocketClient.disconnect()
                @unknown default:
                    break
                }
            }
        }
        .onDisappear {
            Task {
                await MainActor.run {
                    conversationsViewModel.stop()
                }
                await dependencies.chatSocketClient.disconnect()
            }
        }
    }
}
