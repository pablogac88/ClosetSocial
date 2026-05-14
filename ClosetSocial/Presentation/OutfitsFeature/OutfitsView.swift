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
                ContentUnavailableView(
                    "Aún no tienes outfits",
                    systemImage: "square.grid.2x2",
                    description: Text("Combina prendas para crear tu primer look.")
                )
            case let .error(message):
                ContentUnavailableView(
                    "No hemos podido cargar tus outfits",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
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
                        .fill(Color.white)
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

    private var selectedGarments: [Garment] {
        viewModel.availableGarments.filter { selectedIDs.contains($0.id) }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedIDs.isEmpty
            && !viewModel.isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Outfit") {
                    TextField("Título", text: $title)
                    TextField("Nota (opcional)", text: $note, axis: .vertical)
                }

                Section("Prendas") {
                    if viewModel.availableGarments.isEmpty {
                        Text("No tienes prendas en tu armario.")
                            .foregroundStyle(.secondary)
                            .font(DSFont.footnote)
                    } else {
                        ForEach(viewModel.availableGarments) { garment in
                            GarmentPickerRow(
                                garment: garment,
                                isSelected: selectedIDs.contains(garment.id)
                            ) {
                                if selectedIDs.contains(garment.id) {
                                    selectedIDs.remove(garment.id)
                                } else {
                                    selectedIDs.insert(garment.id)
                                }
                            }
                        }
                    }
                }

                if let error = viewModel.saveError {
                    Section {
                        Text(error)
                            .font(DSFont.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Crear outfit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Guardar") {
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
                        .disabled(!canSave)
                    }
                }
            }
            .task { await viewModel.loadAvailableGarments() }
        }
    }
}

private struct GarmentPickerRow: View {
    let garment: Garment
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(garment.name)
                        .foregroundStyle(.primary)
                    Text(garment.type.rawValue)
                        .font(DSFont.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? DSColor.highlightSoft : .secondary)
            }
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
