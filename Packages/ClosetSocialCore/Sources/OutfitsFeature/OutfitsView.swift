import SwiftUI
import Domain
import DesignSystem

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
                    Text(outfit.title).font(DSFont.headline)
                    Text(outfit.note)
                        .font(DSFont.footnote)
                        .foregroundStyle(.secondary)
                    Text(outfit.garmentNames.joined(separator: " · "))
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
    @State private var garmentLine = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Nuevo outfit") {
                    TextField("Título", text: $title)
                    TextField("Nota", text: $note, axis: .vertical)
                    TextField("Prendas separadas por coma", text: $garmentLine, axis: .vertical)
                }
            }
            .navigationTitle("Crear outfit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let garments = garmentLine
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        viewModel.appendLocal(title: title, note: note, garmentNames: garments)
                        dismiss()
                    }
                    .disabled(title.isEmpty || note.isEmpty || garmentLine.isEmpty)
                }
            }
        }
    }
}
