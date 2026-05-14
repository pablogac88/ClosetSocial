import SwiftUI

public struct ClosetView: View {
    @Bindable private var viewModel: ClosetViewModel
    @State private var isPresentingAddSheet = false
    @State private var selectedGarment: Garment?

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
                ContentUnavailableView(
                    "Tu armario está vacío",
                    systemImage: "hanger",
                    description: Text("Añade tu primera prenda para empezar.")
                )
            case let .error(message):
                ContentUnavailableView(
                    "No hemos podido cargar tu armario",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
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
                relatedOutfits: findRelatedOutfits?(garment) ?? []
            )
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
