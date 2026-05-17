import SwiftUI

public struct OutfitsView: View {
    @Bindable private var viewModel: OutfitsViewModel
    @State private var isPresentingCreateSheet = false
    @State private var composerVM: OutfitComposerViewModel?
    @State private var selectedOutfit: Outfit?
    @State private var outfitPendingDeletion: Outfit?
    @State private var deleteErrorMessage: String?

    public init(viewModel: OutfitsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .content(items):
                list(items)
            case .empty:
                EmptyStateView(
                    icon: "square.grid.2x2",
                    title: "Sin looks todavía",
                    message: "Combina prendas del armario y crea tu primer outfit con el compositor visual.",
                    action: .init(label: "Crear look") {
                        composerVM = viewModel.makeComposerViewModel()
                    }
                )
            case let .error(message):
                ContentUnavailableView(
                    "No hemos podido cargar tus outfits",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle("Outfits")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        composerVM = viewModel.makeComposerViewModel()
                    } label: {
                        Label("Crear visual", systemImage: "sparkles")
                    }
                    Button {
                        isPresentingCreateSheet = true
                    } label: {
                        Label("Crear rápido", systemImage: "square.and.pencil")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingCreateSheet) {
            CreateOutfitSheet(viewModel: viewModel)
        }
        .fullScreenCover(item: $composerVM) { vm in
            NavigationStack {
                OutfitComposerView(viewModel: vm)
            }
        }
        .navigationDestination(item: $selectedOutfit) { outfit in
            OutfitDetailView(context: .myOutfit(outfit), onDelete: {
                try await viewModel.delete(outfit)
            })
        }
        .confirmationDialog(
            "Eliminar outfit",
            isPresented: isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            if let outfit = outfitPendingDeletion {
                Button("Eliminar", role: .destructive) {
                    Task { await delete(outfit) }
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se eliminará este outfit y sus prendas seguirán en el armario.")
        }
        .alert("No hemos podido borrar el outfit", isPresented: deleteErrorIsPresented) {
            Button("Aceptar", role: .cancel) { deleteErrorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
        .task { await viewModel.load() }
    }

    private func list(_ items: [Outfit]) -> some View {
        List {
            ForEach(items) { outfit in
                Button { selectedOutfit = outfit } label: {
                    HStack(spacing: 14) {
                        OutfitCanvasView(
                            layout: outfit.layout,
                            garments: outfit.garments,
                            cornerRadius: 10
                        )
                        .frame(width: 52, height: 52)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(outfit.title ?? "Outfit sin título").font(DSFont.headline)
                            if let note = outfit.note {
                                Text(note)
                                    .font(DSFont.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Text(outfit.garments.map(\.name).joined(separator: " · "))
                                .font(DSFont.footnoteBold)
                                .foregroundStyle(DSColor.highlightSoft)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.secondary.opacity(0.4))
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        outfitPendingDeletion = outfit
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                    .tint(.red)
                    .disabled(viewModel.isDeleting(outfit))
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(DSColor.surface)
                        .padding(.vertical, 4)
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .refreshable { await viewModel.load() }
    }

    private var isShowingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { outfitPendingDeletion != nil },
            set: { isPresented in
                if !isPresented { outfitPendingDeletion = nil }
            }
        )
    }

    private var deleteErrorIsPresented: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { isPresented in
                if !isPresented { deleteErrorMessage = nil }
            }
        )
    }

    private func delete(_ outfit: Outfit) async {
        do {
            try await viewModel.delete(outfit)
            if selectedOutfit?.id == outfit.id {
                selectedOutfit = nil
            }
        } catch {
            deleteErrorMessage = error.userMessage
        }
    }
}

private struct CreateOutfitSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: OutfitsViewModel

    @State private var title = ""
    @State private var note = ""
    @State private var selectedIDs: Set<UUID> = []
    @State private var isLoadingGarments = true
    @FocusState private var focusedField: CreateOutfitField?

    private var selectedGarments: [Garment] {
        viewModel.availableGarments.filter { selectedIDs.contains($0.id) }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedIDs.isEmpty
            && !viewModel.isSaving
    }

    var body: some View {
        ZStack(alignment: .top) {
            DSColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 64)

                    fieldsSection
                        .padding(.bottom, 24)

                    garmentsSection
                        .padding(.bottom, 24)

                    if let error = viewModel.saveError {
                        AppErrorBanner(error)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    PrimaryButton(
                        title: "Guardar look",
                        isLoading: viewModel.isSaving,
                        isEnabled: canSave
                    ) {
                        Task {
                            await viewModel.create(
                                title: title.trimmedToNil,
                                note: note.trimmedToNil,
                                garments: selectedGarments
                            )
                            if viewModel.saveError == nil {
                                dismiss()
                            }
                        }
                    }
                    .padding(.bottom, 12)

                    Button("Cancelar") { dismiss() }
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(DSColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .disabled(viewModel.isSaving)

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: viewModel.saveError != nil)
            }
            .scrollDismissesKeyboard(.interactively)

            headerBar
        }
        .presentationCornerRadius(32)
        .task {
            await viewModel.loadAvailableGarments()
            isLoadingGarments = false
        }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack {
            Text("Crear look")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(DSColor.primaryText)

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DSColor.secondaryText)
                    .frame(width: 32, height: 32)
                    .background(DSColor.surface.opacity(0.85), in: Circle())
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                stops: [
                    .init(color: DSColor.background, location: 0.65),
                    .init(color: DSColor.background.opacity(0), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: Fields

    private var fieldsSection: some View {
        VStack(spacing: 14) {
            AppInputField(
                label: "Título",
                text: $title,
                isFocused: focusedField == .title,
                submitLabel: .next,
                onSubmit: { focusedField = .note }
            )
            .focused($focusedField, equals: .title)

            AppInputField(
                label: "Nota (opcional)",
                text: $note,
                isFocused: focusedField == .note,
                submitLabel: .done,
                onSubmit: { focusedField = nil }
            )
            .focused($focusedField, equals: .note)
        }
    }

    // MARK: Garments

    private var garmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Prendas")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(DSColor.tertiaryText)
                    .padding(.leading, 4)

                Spacer()

                if !selectedIDs.isEmpty {
                    Text("\(selectedIDs.count) seleccionada\(selectedIDs.count == 1 ? "" : "s")")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(DSColor.highlight)
                        .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .trailing)))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: selectedIDs.isEmpty)

            if isLoadingGarments {
                HStack(spacing: 10) {
                    ProgressView().scaleEffect(0.8)
                    Text("Cargando armario…")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(DSColor.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else if viewModel.availableGarments.isEmpty {
                EmptyStateView(
                    icon: "hanger",
                    title: "Sin prendas aún",
                    message: "Añade prendas al armario para poder crear un look."
                )
                .frame(height: 200)
                .background(DSColor.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.availableGarments.enumerated()), id: \.element.id) { index, garment in
                        WarmGarmentPickerRow(
                            garment: garment,
                            isSelected: selectedIDs.contains(garment.id)
                        ) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                if selectedIDs.contains(garment.id) {
                                    selectedIDs.remove(garment.id)
                                } else {
                                    selectedIDs.insert(garment.id)
                                }
                            }
                        }

                        if index < viewModel.availableGarments.count - 1 {
                            Divider().padding(.leading, 78)
                        }
                    }
                }
                .background(DSColor.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Focus

private enum CreateOutfitField {
    case title, note
}

// MARK: - Warm garment picker row

private struct WarmGarmentPickerRow: View {
    let garment: Garment
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                GarmentImage(url: garment.imageURL)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(garment.name)
                        .font(.system(.subheadline, design: .rounded, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(DSColor.primaryText)
                    Text(garment.type.name)
                        .font(.system(.caption, design: .rounded, weight: .regular))
                        .foregroundStyle(DSColor.secondaryText)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? DSColor.highlight : DSColor.border,
                            lineWidth: 1.5
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(DSColor.highlight)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? DSColor.highlight.opacity(0.04) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private extension String {
    var trimmedToNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
