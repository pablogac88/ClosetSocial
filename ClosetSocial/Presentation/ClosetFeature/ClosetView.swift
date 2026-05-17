import SwiftUI

public struct ClosetView: View {
    @Bindable private var viewModel: ClosetViewModel
    @State private var isPresentingAddSheet = false
    @State private var selectedGarment: Garment?
    @State private var garmentPendingDeletion: Garment?
    @State private var deleteErrorMessage: String?

    var findRelatedOutfits: ((Garment) -> [Outfit])? = nil

    public init(viewModel: ClosetViewModel, findRelatedOutfits: ((Garment) -> [Outfit])? = nil) {
        self.viewModel            = viewModel
        self.findRelatedOutfits   = findRelatedOutfits
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
                    icon: "hanger",
                    title: "Tu armario está esperando",
                    message: "Añade tu primera prenda y empieza a construir tu estilo.",
                    action: .init(label: "Añadir prenda") { isPresentingAddSheet = true }
                )
            case let .error(message):
                ContentUnavailableView(
                    "No hemos podido cargar tu armario",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle("Armario")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingAddSheet = true
                } label: {
                    Label("Añadir", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddSheet) {
            AddGarmentSheet(viewModel: viewModel.makeAddGarmentViewModel())
        }
        .navigationDestination(item: $selectedGarment) { garment in
            GarmentDetailView(
                garment: garment,
                relatedOutfits: findRelatedOutfits?(garment) ?? [],
                onDelete: {
                try await viewModel.delete(garment)
                }
            )
        }
        .confirmationDialog(
            "Eliminar prenda",
            isPresented: isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            if let garment = garmentPendingDeletion {
                Button("Eliminar", role: .destructive) {
                    Task { await delete(garment) }
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se eliminará \"\(garmentPendingDeletion?.name ?? "esta prenda")\" de tu armario.")
        }
        .alert("No hemos podido borrar la prenda", isPresented: deleteErrorIsPresented) {
            Button("Aceptar", role: .cancel) { deleteErrorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
        .task { await viewModel.load() }
    }

    private func list(_ items: [Garment]) -> some View {
        List {
            ForEach(items) { item in
                Button { selectedGarment = item } label: {
                    HStack(spacing: 14) {
                        GarmentImage(url: item.imageURL)
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).font(DSFont.headline)
                            Text(item.subtitle)
                                .font(DSFont.footnote)
                                .foregroundStyle(.secondary)
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
                        garmentPendingDeletion = item
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                    .tint(.red)
                    .disabled(viewModel.isDeleting(item))
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
        .refreshable { await viewModel.refresh() }
    }

    private var deleteErrorIsPresented: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { isPresented in
                if !isPresented { deleteErrorMessage = nil }
            }
        )
    }

    private var isShowingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { garmentPendingDeletion != nil },
            set: { isPresented in
                if !isPresented { garmentPendingDeletion = nil }
            }
        )
    }

    private func delete(_ garment: Garment) async {
        do {
            try await viewModel.delete(garment)
            if selectedGarment?.id == garment.id {
                selectedGarment = nil
            }
        } catch {
            deleteErrorMessage = error.userMessage
        }
    }
}

private extension Garment {
    var subtitle: String {
        [brand, type.rawValue, color]
            .compactMap { value in
                guard let value else { return nil }
                return value.isEmpty ? nil : value
            }
            .joined(separator: " · ")
    }
}
