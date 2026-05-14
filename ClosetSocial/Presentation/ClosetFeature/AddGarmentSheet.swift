import SwiftUI
import UIKit

struct AddGarmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AddGarmentViewModel
    @FocusState private var focusedField: GarmentField?

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.975, green: 0.970, blue: 0.962)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 64)

                    imageSection
                        .padding(.bottom, 28)

                    fieldsSection
                        .padding(.bottom, 24)

                    typeSection
                        .padding(.bottom, 24)

                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    PrimaryButton(
                        title: "Guardar prenda",
                        isLoading: viewModel.isSaving,
                        isEnabled: !viewModel.isSaveDisabled
                    ) {
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    }
                    .padding(.bottom, 12)

                    Button("Cancelar") { dismiss() }
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Color(red: 0.58, green: 0.52, blue: 0.48))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .disabled(viewModel.isSaving)

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
            }
            .scrollDismissesKeyboard(.interactively)

            headerBar
        }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack {
            Text("Nueva prenda")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(red: 0.14, green: 0.11, blue: 0.09))

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.44, green: 0.38, blue: 0.34))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.85), in: Circle())
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
                    .init(color: Color(red: 0.975, green: 0.970, blue: 0.962), location: 0.65),
                    .init(color: Color(red: 0.975, green: 0.970, blue: 0.962).opacity(0), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: Image section

    private var imageSection: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.945, green: 0.938, blue: 0.922))

                if let url = previewURL {
                    GarmentImage(url: url)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo")
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(Color(red: 0.68, green: 0.62, blue: 0.56))

                        Text("Preview de imagen")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(Color(red: 0.72, green: 0.66, blue: 0.60))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)

            GarmentInputField(
                label: "URL de imagen",
                text: $viewModel.imageURL,
                keyboardType: .URL,
                autocapitalization: .never,
                isFocused: focusedField == .imageURL,
                submitLabel: .next,
                onSubmit: { focusedField = .name }
            )
            .focused($focusedField, equals: .imageURL)
        }
    }

    private var previewURL: URL? {
        let trimmed = viewModel.imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    // MARK: Fields

    private var fieldsSection: some View {
        VStack(spacing: 14) {
            GarmentInputField(
                label: "Nombre",
                text: $viewModel.name,
                isFocused: focusedField == .name,
                submitLabel: .next,
                onSubmit: { focusedField = .brand }
            )
            .focused($focusedField, equals: .name)

            GarmentInputField(
                label: "Marca",
                text: $viewModel.brand,
                isFocused: focusedField == .brand,
                submitLabel: .next,
                onSubmit: { focusedField = .color }
            )
            .focused($focusedField, equals: .brand)

            GarmentInputField(
                label: "Color",
                text: $viewModel.color,
                isFocused: focusedField == .color,
                submitLabel: .done,
                onSubmit: { focusedField = nil }
            )
            .focused($focusedField, equals: .color)
        }
    }

    // MARK: Type selector

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tipo de prenda")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(red: 0.62, green: 0.56, blue: 0.52))
                .padding(.leading, 4)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                spacing: 10
            ) {
                ForEach(GarmentType.allCases) { type in
                    TypeChip(
                        title: type.rawValue,
                        isSelected: viewModel.type == type
                    ) {
                        viewModel.type = type
                    }
                }
            }
        }
    }

    // MARK: Error

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(red: 0.72, green: 0.18, blue: 0.18))

            Text(message)
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(Color(red: 0.55, green: 0.12, blue: 0.12))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color(red: 1.0, green: 0.93, blue: 0.93),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

// MARK: - Focus fields

private enum GarmentField {
    case imageURL, name, brand, color
}

// MARK: - Input field

private struct GarmentInputField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isFocused: Bool = false
    var submitLabel: SubmitLabel = .next
    var onSubmit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(
                    isFocused
                        ? Color(red: 0.25, green: 0.30, blue: 0.58)
                        : Color(red: 0.62, green: 0.56, blue: 0.52)
                )
                .animation(.easeInOut(duration: 0.15), value: isFocused)

            TextField("", text: $text)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundStyle(Color(red: 0.14, green: 0.11, blue: 0.09))
                .submitLabel(submitLabel)
                .onSubmit(onSubmit)
                .frame(height: 28)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isFocused
                                ? Color(red: 0.25, green: 0.30, blue: 0.58).opacity(0.5)
                                : Color.clear,
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: isFocused
                        ? Color(red: 0.25, green: 0.30, blue: 0.58).opacity(0.10)
                        : Color.black.opacity(0.04),
                    radius: isFocused ? 8 : 4,
                    x: 0,
                    y: 2
                )
                .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}

// MARK: - Type chip

private struct TypeChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(
                    isSelected
                        ? Color.white
                        : Color(red: 0.36, green: 0.31, blue: 0.28)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected
                        ? Color(red: 0.10, green: 0.08, blue: 0.07)
                        : Color.white,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .shadow(
                    color: isSelected ? Color.black.opacity(0.14) : Color.black.opacity(0.04),
                    radius: isSelected ? 6 : 3,
                    x: 0,
                    y: 2
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}
