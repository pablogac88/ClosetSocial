import SwiftUI

public struct ExploreView: View {
    @Bindable private var viewModel: ExploreViewModel
    private let makePublicProfileViewModel: (UUID) -> PublicProfileViewModel
    private let startConversation: @MainActor (UUID) async throws -> Conversation
    private let makeChatDetailViewModel: (Conversation) -> ChatDetailViewModel

    @State private var selectedOutfit: Outfit?
    @State private var selectedGarment: Garment?
    @State private var selectedUserID: UUID?

    public init(
        viewModel: ExploreViewModel,
        makePublicProfileViewModel: @escaping (UUID) -> PublicProfileViewModel,
        startConversation: @escaping @MainActor (UUID) async throws -> Conversation,
        makeChatDetailViewModel: @escaping (Conversation) -> ChatDetailViewModel
    ) {
        self.viewModel = viewModel
        self.makePublicProfileViewModel = makePublicProfileViewModel
        self.startConversation = startConversation
        self.makeChatDetailViewModel = makeChatDetailViewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            tabsBar
            Divider()
                .overlay(DSColor.border)
            feedContent
        }
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedOutfit) { initial in
            let liveItem = viewModel.findOutfitItem(forOutfitID: initial.id)
            OutfitDetailView(
                context: .myOutfit(liveItem?.outfit ?? initial),
                onSaveTap: liveItem.map { item in { Task { await viewModel.toggleSave(for: item) } } }
            )
        }
        .navigationDestination(item: $selectedGarment) { garment in
            GarmentDetailView(
                garment: garment,
                relatedOutfits: viewModel.relatedOutfits(for: garment.id)
            )
        }
        .navigationDestination(item: $selectedUserID) { userID in
            PublicProfileView(
                viewModel: makePublicProfileViewModel(userID),
                startConversation: startConversation,
                makeChatDetailViewModel: makeChatDetailViewModel
            )
        }
        .task(id: viewModel.selectedTab) { await viewModel.loadTabIfNeeded() }
        .task(id: viewModel.searchText) { await viewModel.handleSearchTextChanged() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Descubre")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(DSColor.primaryText)

            Text(subtitle)
                .font(DSFont.body)
                .foregroundStyle(DSColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var subtitle: String {
        if viewModel.shouldUseBackendSearch {
            switch viewModel.selectedTab {
            case .looks: return "Outfits reales encontrados por tu búsqueda"
            case .garments: return "Prendas reales encontradas por tu búsqueda"
            case .people: return "Personas reales encontradas por tu búsqueda"
            }
        }

        switch viewModel.selectedTab {
        case .looks: return "Looks reales de la comunidad, en formato editorial"
        case .garments: return "Prendas reales para descubrir materiales, marcas y estilo"
        case .people: return "Perfiles reales con movimiento y estilo propio"
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DSColor.secondaryText)

            TextField("Busca looks, prendas o personas", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(DSFont.body)
                .foregroundStyle(DSColor.primaryText)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DSColor.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(DSColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(DSColor.border, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var tabsBar: some View {
        HStack(spacing: 10) {
            ForEach(ExploreTab.allCases) { tab in
                Button {
                    viewModel.selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(viewModel.selectedTab == tab ? DSColor.actionPrimaryForeground : DSColor.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedTab == tab ? DSColor.actionPrimaryBackground : DSColor.surface)
                        )
                        .overlay(
                            Capsule()
                                .stroke(viewModel.selectedTab == tab ? Color.clear : DSColor.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var feedContent: some View {
        TabView(selection: $viewModel.selectedTab) {
            looksFeed.tag(ExploreTab.looks)
            garmentsFeed.tag(ExploreTab.garments)
            peopleFeed.tag(ExploreTab.people)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var looksFeed: some View {
        ExploreFeedContainer(
            state: viewModel.looksState,
            emptyTitle: "Sin looks por ahora",
            emptyMessage: viewModel.shouldUseBackendSearch
                ? "Prueba con otra búsqueda para encontrar más outfits."
                : "Cuando haya más outfits reales, aparecerán aquí.",
            errorTitle: "No hemos podido cargar looks",
            hintMessage: viewModel.isShortQuery ? "Escribe al menos 2 caracteres para buscar. Mientras tanto seguimos mostrándote discovery real." : nil,
            onRefresh: { await viewModel.refreshSelectedTab() }
        ) { items in
            ExploreMediaGrid(items: items) { item in
                ExploreLookTile(item: item) {
                    selectedOutfit = item.outfit
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
    }

    private var garmentsFeed: some View {
        ExploreFeedContainer(
            state: viewModel.garmentsState,
            emptyTitle: "Sin prendas por ahora",
            emptyMessage: viewModel.shouldUseBackendSearch
                ? "Prueba con otra búsqueda para descubrir más prendas."
                : "Cuando entren más prendas reales, se verán aquí.",
            errorTitle: "No hemos podido cargar prendas",
            hintMessage: viewModel.isShortQuery ? "Escribe al menos 2 caracteres para buscar. Mientras tanto seguimos mostrándote discovery real." : nil,
            onRefresh: { await viewModel.refreshSelectedTab() }
        ) { items in
            ExploreMediaGrid(items: items) { item in
                ExploreGarmentTile(item: item) {
                    selectedGarment = item.garment
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
    }

    private var peopleFeed: some View {
        ExploreFeedContainer(
            state: viewModel.peopleState,
            emptyTitle: "Sin personas por ahora",
            emptyMessage: viewModel.shouldUseBackendSearch
                ? "Prueba con otro nombre o username para encontrar personas."
                : "Cuando haya más usuarios activos, aparecerán aquí.",
            errorTitle: "No hemos podido cargar personas",
            hintMessage: viewModel.isShortQuery ? "Escribe al menos 2 caracteres para buscar. Mientras tanto seguimos mostrándote discovery real." : nil,
            onRefresh: { await viewModel.refreshSelectedTab() }
        ) { items in
            LazyVStack(spacing: 20) {
                ForEach(items) { item in
                    ExplorePersonCard(
                        item: item,
                        currentUserID: viewModel.currentUserID,
                        isFollowingLoading: viewModel.isFollowingLoading(item),
                        onTap: { selectedUserID = item.id },
                        onFollowTap: { Task { await viewModel.toggleFollow(for: item) } }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
    }
}

private struct ExploreMediaGrid<Item: Identifiable, Tile: View>: View {
    let items: [Item]
    @ViewBuilder let tile: (Item) -> Tile

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(items) { item in
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        tile(item)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .clipped()
            }
        }
        .padding(.horizontal, 2)
    }
}

private struct ExploreFeedContainer<Item: Sendable & Equatable, Content: View>: View {
    let state: ExploreFeedState<Item>
    let emptyTitle: String
    let emptyMessage: String
    let errorTitle: String
    let hintMessage: String?
    let onRefresh: @Sendable () async -> Void
    @ViewBuilder let content: ([Item]) -> Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if let hintMessage {
                    ExploreHintCard(message: hintMessage)
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                }

                switch state {
                case .idle, .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                case let .content(items):
                    content(items)
                case .empty:
                    EmptyStateView(
                        icon: "sparkles",
                        title: emptyTitle,
                        message: emptyMessage
                    )
                    .padding(.top, 46)
                case let .error(message):
                    ContentUnavailableView(
                        errorTitle,
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                    .padding(.top, 46)
                }
            }
        }
        .refreshable { await onRefresh() }
    }
}

private struct ExploreHintCard: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "text.cursor")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DSColor.highlight)
            Text(message)
                .font(DSFont.footnote)
                .foregroundStyle(DSColor.secondaryText)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(DSColor.surfaceElevated)
        )
    }
}

private struct ExploreLookTile: View {
    let item: ExploreOutfitItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Color.clear
                .overlay {
                    if let coverImageURL = item.outfit.coverImageURL {
                        GarmentImage(url: coverImageURL)
                    } else {
                        OutfitCanvasView(
                            layout: item.outfit.layout,
                            garments: item.outfit.garments,
                            cornerRadius: 0,
                            backgroundColor: DSColor.surfaceElevated
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .background(DSColor.surfaceElevated)
                .clipped()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ExploreGarmentTile: View {
    let item: ExploreGarmentItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GarmentImage(url: item.garment.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DSColor.surfaceElevated)
                .clipped()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ExplorePersonCard: View {
    let item: ExploreUserItem
    let currentUserID: UUID?
    let isFollowingLoading: Bool
    let onTap: () -> Void
    let onFollowTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                AvatarBubble(
                    displayName: item.user.displayName,
                    avatarURL: item.user.avatarURL,
                    size: 60,
                    fillColor: DSColor.warmFill,
                    textColor: DSColor.secondaryText
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.user.displayName)
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                        .foregroundStyle(DSColor.primaryText)
                        .multilineTextAlignment(.leading)
                    Text("@\(item.user.username)")
                        .font(.system(.subheadline, design: .rounded, weight: .regular))
                        .foregroundStyle(DSColor.secondaryText)

                    if let bio = item.user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(DSFont.body)
                            .foregroundStyle(DSColor.secondaryText)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 10) {
                ExploreMetaPill(label: "\(item.outfitCount) looks")
                ExploreMetaPill(label: "\(item.closetCount) prendas")
                ExploreMetaPill(label: "\(item.followerCount) seguidores")
            }

            if currentUserID != item.id {
                Button(action: onFollowTap) {
                    HStack(spacing: 8) {
                        if isFollowingLoading {
                            ProgressView()
                                .tint(item.isFollowing ? DSColor.actionSecondaryForeground : DSColor.actionPrimaryForeground)
                                .scaleEffect(0.9)
                        }
                        Text(item.isFollowing ? "Siguiendo" : "Seguir")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(item.isFollowing ? DSColor.actionSecondaryBackground : DSColor.actionPrimaryBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(item.isFollowing ? DSColor.border : Color.clear, lineWidth: 1)
                    )
                    .foregroundStyle(item.isFollowing ? DSColor.actionSecondaryForeground : DSColor.actionPrimaryForeground)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DSColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(DSColor.border.opacity(0.85), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture(perform: onTap)
    }
}

private struct ExploreMetaPill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(DSColor.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(DSColor.surfaceElevated)
            )
    }
}
