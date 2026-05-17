import SwiftUI
import PhotosUI

struct AddGarmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AddGarmentViewModel
    @FocusState private var focusedField: GarmentField?
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        ZStack(alignment: .top) {
            DSColor.background
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

                    if let error = viewModel.uploadError {
                        AppErrorBanner(error)
                            .padding(.bottom, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if let error = viewModel.errorMessage {
                        AppErrorBanner(error)
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
                        .foregroundStyle(DSColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .disabled(viewModel.isSaving || viewModel.isUploading)

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
                .animation(.easeInOut(duration: 0.2), value: viewModel.uploadError)
            }
            .scrollDismissesKeyboard(.interactively)

            headerBar
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await viewModel.handleImagePicked(data)
                } else {
                    viewModel.uploadError = "No se pudo cargar la imagen seleccionada."
                }
                pickerItem = nil
            }
        }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack {
            Text("Nueva prenda")
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
            .disabled(viewModel.isSaving || viewModel.isUploading)
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

    // MARK: Image section

    private var imageSection: some View {
        let isUploading = viewModel.isUploading
        let pickedData = viewModel.pickedImageData
        let uploadedURL = viewModel.uploadedImageURL
        let hasImage = uploadedURL != nil

        return ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DSColor.imagePlaceholder)

            Group {
                if isUploading {
                    VStack(spacing: 12) {
                        ProgressView().scaleEffect(1.2)
                        Text("Subiendo imagen…")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(DSColor.secondaryText)
                    }
                } else if let data = pickedData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .transition(.opacity.animation(.easeIn(duration: 0.22)))
                } else if let url = uploadedURL {
                    GarmentImage(url: url)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(DSColor.tertiaryText)
                        Text("Añadir foto")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(DSColor.tertiaryText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 5) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(hasImage ? "Cambiar" : "Foto")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(DSColor.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DSColor.surface.opacity(0.88), in: Capsule())
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)
            .opacity(isUploading ? 0 : 1)
            .padding(12)
        }
        .contentShape(Rectangle())
        .overlay {
            PhotosPicker(
                selection: $pickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Color.clear
            }
            .buttonStyle(.plain)
            .disabled(isUploading)
        }
    }

    // MARK: Fields

    private var fieldsSection: some View {
        VStack(spacing: 14) {
            AppInputField(
                label: "Nombre",
                text: $viewModel.name,
                isFocused: focusedField == .name,
                submitLabel: .next,
                onSubmit: { focusedField = .brand }
            )
            .focused($focusedField, equals: .name)

            AppInputField(
                label: "Marca",
                text: $viewModel.brand,
                isFocused: focusedField == .brand,
                submitLabel: .next,
                onSubmit: { focusedField = .color }
            )
            .focused($focusedField, equals: .brand)

            AppInputField(
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
                .foregroundStyle(DSColor.tertiaryText)
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
}

// MARK: - Focus fields

private enum GarmentField {
    case name, brand, color
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
                        : DSColor.secondaryText
                )
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected
                        ? Color(red: 0.10, green: 0.08, blue: 0.07)
                        : DSColor.surface,
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
