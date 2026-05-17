import SwiftUI

public struct GarmentDetailView: View {
    let garment: Garment
    let relatedOutfits: [Outfit]
    var onDelete: (() async throws -> Void)? = nil

    @State private var selectedOutfit: Outfit?
    @State private var isShowingDeleteConfirmation = false
    @State private var deleteErrorMessage: String?
    @Environment(\.dismiss) private var dismiss

    public init(
        garment: Garment,
        relatedOutfits: [Outfit] = [],
        onDelete: (() async throws -> Void)? = nil
    ) {
        self.garment       = garment
        self.relatedOutfits = relatedOutfits
        self.onDelete = onDelete
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero
                metadataSection
                if !relatedOutfits.isEmpty {
                    looksSection
                }
                Color.clear.frame(height: 40)
            }
        }
        .background(DSColor.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(garment.type.rawValue)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(DSColor.primaryText.opacity(0.7))
            }
            if onDelete != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .sheet(item: $selectedOutfit) { outfit in
            NavigationStack {
                OutfitDetailView(context: .myOutfit(outfit))
            }
        }
        .confirmationDialog(
            "Eliminar prenda",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                Task { await deleteGarment() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se eliminará \"\(garment.name)\" de tu armario.")
        }
        .alert("No hemos podido borrar la prenda", isPresented: deleteErrorIsPresented) {
            Button("Aceptar", role: .cancel) { deleteErrorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
    }

    // MARK: Hero

    private var hero: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .aspectRatio(1 / 1.1, contentMode: .fit)
            .overlay { GarmentImage(url: garment.imageURL) }
            .clipShape(UnevenRoundedRectangle(
                bottomLeadingRadius: 28,
                bottomTrailingRadius: 28
            ))
            .shadow(color: .black.opacity(0.09), radius: 28, x: 0, y: 12)
            .shadow(color: .black.opacity(0.03), radius: 4,  x: 0, y: 2)
    }

    // MARK: Metadata

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(garment.name)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(DSColor.primaryText)

                if let brand = garment.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.system(.title3, design: .rounded, weight: .regular))
                        .foregroundStyle(Color(red: 0.44, green: 0.39, blue: 0.35))
                }
            }

            HStack(spacing: 8) {
                MetaPill(label: garment.type.rawValue)
                if !garment.color.isEmpty {
                    MetaPill(label: garment.color)
                }
            }

            Text(garment.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(DSColor.tertiaryText)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 8)
    }

    // MARK: Looks

    private var looksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Looks con esta prenda")
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(DSColor.secondaryText)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(relatedOutfits) { outfit in
                        LookbookCard(outfit: outfit) {
                            selectedOutfit = outfit
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 36)
    }
}

private extension GarmentDetailView {
    var deleteErrorIsPresented: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { isPresented in
                if !isPresented { deleteErrorMessage = nil }
            }
        )
    }

    func deleteGarment() async {
        guard let onDelete else { return }
        do {
            try await onDelete()
            dismiss()
        } catch {
            deleteErrorMessage = error.userMessage
        }
    }
}

// MARK: - Meta pill

private struct MetaPill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(Color(red: 0.44, green: 0.39, blue: 0.35))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Color(red: 0.91, green: 0.88, blue: 0.84).opacity(0.8),
                in: Capsule()
            )
    }
}

// MARK: - Lookbook card

private struct LookbookCard: View {
    let outfit: Outfit
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                OutfitCanvasView(
                    layout: outfit.layout,
                    garments: outfit.garments,
                    cornerRadius: 20
                )
                .aspectRatio(3 / 4, contentMode: .fit)
                .frame(width: 160)
                .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 5)
                .shadow(color: .black.opacity(0.03), radius: 3,  x: 0, y: 1)

                if let title = outfit.title {
                    Text(title)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(DSColor.primaryText)
                        .lineLimit(1)
                        .frame(width: 160, alignment: .leading)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
