import SwiftUI

struct GarmentGridView: View {
    let garments: [Garment]
    let categories: [GarmentCategory]
    let onTap: (Garment) -> Void
    let onRefresh: (@Sendable () async -> Void)?

    @State private var selectedCategory: GarmentCategory?

    init(
        garments: [Garment],
        categories: [GarmentCategory] = [],
        onTap: @escaping (Garment) -> Void,
        onRefresh: (@Sendable () async -> Void)? = nil
    ) {
        self.garments = garments
        self.categories = categories
        self.onTap = onTap
        self.onRefresh = onRefresh
    }

    private var filtered: [Garment] {
        guard let cat = selectedCategory else { return garments }
        return garments.filter { garment in
            cat.subtypes.contains { $0.id == garment.type.id }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: []) {
                if !categories.isEmpty {
                    filterBar
                        .padding(.top, 14)
                        .padding(.bottom, 8)
                }
                grid
                    .padding(.horizontal, 16)
                    .padding(.top, categories.isEmpty ? 16 : 8)
                    .padding(.bottom, 32)
            }
        }
        .refreshable { await onRefresh?() }
    }

    // MARK: Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(label: "Todo", isSelected: selectedCategory == nil) {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedCategory = nil }
                }
                ForEach(categories) { cat in
                    filterPill(label: cat.name, isSelected: selectedCategory?.id == cat.id) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedCategory = selectedCategory?.id == cat.id ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterPill(label: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(.subheadline, design: .rounded, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? DSColor.actionPrimaryForeground : DSColor.secondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(isSelected ? DSColor.actionPrimaryBackground : DSColor.surface)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : DSColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Grid

    private var grid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 16
        ) {
            ForEach(filtered) { garment in
                GarmentCard(garment: garment, onTap: { onTap(garment) })
            }
        }
    }
}

// MARK: - Garment card

private struct GarmentCard: View {
    let garment: Garment
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Image
                Color.clear
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .overlay { GarmentImage(url: garment.imageURL) }
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(garment.name)
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(DSColor.primaryText)
                        .lineLimit(1)

                    Text(garment.type.name)
                        .font(.system(.caption2, design: .rounded, weight: .regular))
                        .foregroundStyle(DSColor.tertiaryText)

                    HStack(spacing: 6) {
                        if let brand = garment.brand, !brand.isEmpty {
                            Text(brand)
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .foregroundStyle(DSColor.secondaryText)
                                .lineLimit(1)
                        }
                        if !garment.color.isEmpty {
                            ColorPill(color: garment.color)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color pill

private struct ColorPill: View {
    let color: String

    var body: some View {
        Text(color)
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundStyle(DSColor.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(DSColor.surfaceElevated, in: Capsule())
    }
}
