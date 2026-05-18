import SwiftUI

public enum StyleTab: String, CaseIterable, Sendable {
    case garments  = "Prendas"
    case looks     = "Looks"
    case saved     = "Guardados"
}

public struct StyleView: View {
    @Bindable private var closetViewModel: ClosetViewModel
    @Bindable private var outfitsViewModel: OutfitsViewModel

    @State private var selectedTab: StyleTab = .garments
    @State private var selectedGarment: Garment?
    @State private var selectedOutfit: Outfit?
    @State private var composerVM: OutfitComposerViewModel?
    @State private var isPresentingAddSheet = false
    @State private var outfitPendingDeletion: Outfit?
    @State private var deleteErrorMessage: String?

    public init(closetViewModel: ClosetViewModel, outfitsViewModel: OutfitsViewModel) {
        self.closetViewModel = closetViewModel
        self.outfitsViewModel = outfitsViewModel
    }

    // MARK: Body

    public var body: some View {
        VStack(spacing: 0) {
            header
            tabBar
            tabContent
        }
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedGarment) { garment in
            GarmentDetailView(
                garment: garment,
                relatedOutfits: relatedOutfits(for: garment),
                onDelete: { try await closetViewModel.delete(garment) }
            )
        }
        .navigationDestination(item: $selectedOutfit) { outfit in
            OutfitDetailView(
                context: .myOutfit(outfit),
                onDelete: { try await deleteOutfit(outfit) }
            )
        }
        .fullScreenCover(item: $composerVM) { vm in
            NavigationStack { OutfitComposerView(viewModel: vm) }
        }
        .sheet(isPresented: $isPresentingAddSheet) {
            AddGarmentSheet(viewModel: closetViewModel.makeAddGarmentViewModel())
        }
        .confirmationDialog(
            "Eliminar look",
            isPresented: Binding(
                get: { outfitPendingDeletion != nil },
                set: { if !$0 { outfitPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let outfit = outfitPendingDeletion {
                Button("Eliminar", role: .destructive) {
                    Task { try? await outfitsViewModel.delete(outfit) }
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se eliminará este look. Las prendas seguirán en tu armario.")
        }
        .alert("No hemos podido borrar", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("Aceptar", role: .cancel) { deleteErrorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
        .task { await closetViewModel.load() }
        .task { await closetViewModel.loadCategories() }
        .task(id: outfitsViewModel.selectedTab) { await outfitsViewModel.loadActiveTab() }
        .onChange(of: selectedTab) { _, newTab in
            switch newTab {
            case .garments: break
            case .looks:
                outfitsViewModel.selectedTab = .myOutfits
                Task { await outfitsViewModel.loadMyOutfits(silent: true) }
            case .saved:
                outfitsViewModel.selectedTab = .saved
                Task { await outfitsViewModel.loadSaved(silent: true) }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Estilo")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(DSColor.primaryText)
            }
            Spacer()
            headerActions
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var headerActions: some View {
        switch selectedTab {
        case .garments:
            Button {
                isPresentingAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DSColor.primaryText)
                    .frame(width: 36, height: 36)
                    .background(DSColor.surface, in: Circle())
            }
            .buttonStyle(.plain)
        case .looks:
            Menu {
                Button {
                    composerVM = outfitsViewModel.makeComposerViewModel()
                } label: {
                    Label("Crear visual", systemImage: "sparkles")
                }
                Button {
                    // quick create — handled by OutfitsViewModel.create, add if needed
                } label: {
                    Label("Crear rápido", systemImage: "square.and.pencil")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DSColor.primaryText)
                    .frame(width: 36, height: 36)
                    .background(DSColor.surface, in: Circle())
            }
        case .saved:
            EmptyView()
        }
    }

    // MARK: Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(StyleTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedTab = tab }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(.subheadline, design: .rounded,
                                          weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? DSColor.primaryText : DSColor.tertiaryText)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(selectedTab == tab ? DSColor.primaryText : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(DSColor.background)
    }

    // MARK: Tab content

    @ViewBuilder
    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            garmentsTab.tag(StyleTab.garments)
            looksTab.tag(StyleTab.looks)
            savedTab.tag(StyleTab.saved)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    // MARK: Garments tab

    @ViewBuilder
    private var garmentsTab: some View {
        switch closetViewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .content(garments):
            GarmentGridView(
                garments: garments,
                categories: closetViewModel.categories,
                onTap: { selectedGarment = $0 },
                onRefresh: { await closetViewModel.refresh() }
            )
        case .empty:
            EmptyStateView(
                icon: "hanger",
                title: "Tu colección está vacía",
                message: "Añade tu primera prenda y empieza a construir tu estilo.",
                action: .init(label: "Añadir prenda") { isPresentingAddSheet = true }
            )
        case let .error(message):
            ContentUnavailableView(
                "No hemos podido cargar tus prendas",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }

    // MARK: Looks tab

    @ViewBuilder
    private var looksTab: some View {
        switch outfitsViewModel.myOutfitsState {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .content(outfits):
            outfitGrid(outfits, context: .looks)
        case .empty:
            EmptyStateView(
                icon: "sparkles",
                title: "Aún no tienes looks",
                message: "Crea tu primer look combinando prendas de tu armario.",
                action: .init(label: "Crear look") {
                    composerVM = outfitsViewModel.makeComposerViewModel()
                }
            )
        case let .error(message):
            ContentUnavailableView(
                "No hemos podido cargar tus looks",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }

    // MARK: Saved tab

    @ViewBuilder
    private var savedTab: some View {
        switch outfitsViewModel.savedState {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .content(outfits):
            outfitGrid(outfits, context: .saved)
        case .empty:
            EmptyStateView(
                icon: "bookmark",
                title: "Nada guardado todavía",
                message: "Guarda looks que te inspiren desde Descubrir y tenlos todos aquí.",
                action: .init(label: "Explorar looks") { /* TODO: deep link to Explore */ }
            )
        case let .error(message):
            ContentUnavailableView(
                "No hemos podido cargar guardados",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }

    // MARK: Outfit grid

    private func outfitGrid(_ outfits: [Outfit], context: StyleTab) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 16
            ) {
                ForEach(outfits) { outfit in
                    OutfitGridCard(outfit: outfit) {
                        selectedOutfit = outfit
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .refreshable {
            switch context {
            case .looks:  await outfitsViewModel.loadMyOutfits(silent: true)
            case .saved:  await outfitsViewModel.loadSaved(silent: true)
            case .garments: break
            }
        }
    }

    // MARK: Helpers

    private func relatedOutfits(for garment: Garment) -> [Outfit] {
        guard case .content(let outfits) = outfitsViewModel.myOutfitsState else { return [] }
        return outfits.filter { $0.garments.contains { $0.id == garment.id } }
    }

    private func deleteOutfit(_ outfit: Outfit) async throws {
        try await outfitsViewModel.delete(outfit)
    }
}

// MARK: - Outfit grid card

private struct OutfitGridCard: View {
    let outfit: Outfit
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Color.clear
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .overlay {
                        if let coverURL = outfit.coverImageURL {
                            GarmentImage(url: coverURL)
                        } else {
                            OutfitCanvasView(
                                layout: outfit.layout,
                                garments: outfit.garments,
                                cornerRadius: 0,
                                backgroundColor: DSColor.surfaceElevated
                            )
                        }
                    }
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)

                if let title = outfit.title {
                    Text(title)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(DSColor.primaryText)
                        .lineLimit(1)
                        .padding(.horizontal, 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
