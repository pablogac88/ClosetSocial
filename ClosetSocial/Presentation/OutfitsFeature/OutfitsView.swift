import SwiftUI

public struct OutfitsView: View {
    @Bindable private var viewModel: OutfitsViewModel
    @State private var isPresentingCreateSheet = false

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
                Button {
                    isPresentingCreateSheet = true
                } label: {
                    Label("Crear outfit", systemImage: "sparkles")
                }
            }
        }
        .sheet(isPresented: $isPresentingCreateSheet) {
            CreateOutfitSheet(viewModel: viewModel)
        }
        .task { await viewModel.load() }
    }

    private func list(_ items: [Outfit]) -> some View {
        List {
            ForEach(items) { outfit in
                VStack(alignment: .leading, spacing: 8) {
                    Text(outfit.title ?? "Outfit sin título").font(DSFont.headline)
                    if let note = outfit.note {
                        Text(note)
                            .font(DSFont.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Text(outfit.garments.map(\.name).joined(separator: " · "))
                        .font(DSFont.footnoteBold)
                        .foregroundStyle(DSColor.highlightSoft)
                }
                .padding(.vertical, 6)
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
