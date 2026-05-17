import SwiftUI

struct BrandPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBrand: String
    let brands: [Brand]

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var filteredBrands: [Brand] {
        guard !searchText.isEmpty else { return brands }
        let query = searchText.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return brands.filter {
            $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .contains(query)
        }
    }

    private var showFreeTextOption: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return !brands.contains { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
    }

    var body: some View {
        ZStack(alignment: .top) {
            DSColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                searchBar
                brandList
            }
        }
        .onAppear { isSearchFocused = true }
    }

    private var headerBar: some View {
        HStack {
            Text("Marca")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(DSColor.primaryText)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DSColor.secondaryText)
                    .frame(width: 32, height: 32)
                    .background(DSColor.surface.opacity(0.85), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DSColor.tertiaryText)

            TextField("Buscar o escribir marca", text: $searchText)
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundStyle(DSColor.primaryText)
                .focused($isSearchFocused)
                .submitLabel(.done)
                .onSubmit { pickFreeText() }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DSColor.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(DSColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var brandList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if showFreeTextOption {
                    freeTextRow
                    Divider().padding(.leading, 20)
                }

                if filteredBrands.isEmpty && !showFreeTextOption {
                    Text("Sin resultados")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(DSColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    ForEach(filteredBrands) { brand in
                        brandRow(brand)
                        if brand.id != filteredBrands.last?.id {
                            Divider().padding(.leading, 20)
                        }
                    }
                }
            }
        }
    }

    private var freeTextRow: some View {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return Button {
            selectedBrand = trimmed
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DSColor.accent)
                    .frame(width: 24)
                Text("Usar \"\(trimmed)\"")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(DSColor.primaryText)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func brandRow(_ brand: Brand) -> some View {
        Button {
            selectedBrand = brand.name
            dismiss()
        } label: {
            HStack {
                Text(brand.name)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(DSColor.primaryText)
                Spacer()
                if selectedBrand == brand.name {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DSColor.accent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func pickFreeText() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        selectedBrand = trimmed
        dismiss()
    }
}
