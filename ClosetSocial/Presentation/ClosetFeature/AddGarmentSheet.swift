import SwiftUI
import PhotosUI
import AVFoundation

struct AddGarmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AddGarmentViewModel
    @FocusState private var focusedField: GarmentField?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showSourcePicker = false
    @State private var showGallery = false
    @State private var showCamera = false
    @State private var showCameraPermissionAlert = false
    @State private var showBrandPicker = false

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

                    categorySection
                        .padding(.bottom, 24)

                    if let error = viewModel.imageUpload.errorMessage {
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
                        .disabled(viewModel.isSaving || viewModel.imageUpload.isUploading)

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
                .animation(.easeInOut(duration: 0.2), value: viewModel.imageUpload.errorMessage)
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
                    viewModel.errorMessage = "No se pudo cargar la imagen seleccionada."
                }
                pickerItem = nil
            }
        }
        .task {
            await viewModel.loadGarmentTypesIfNeeded()
        }
        .confirmationDialog(
            "Foto de la prenda",
            isPresented: $showSourcePicker,
            titleVisibility: .visible
        ) {
            Button("Elegir de galería") { showGallery = true }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Hacer foto") { openCamera() }
            }
            if viewModel.imageUpload.hasImage {
                Button("Eliminar imagen", role: .destructive) {
                    viewModel.imageUpload.remove()
                }
            }
            Button("Cancelar", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showGallery,
            selection: $pickerItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .sheet(isPresented: $showCamera) {
            CameraPicker(
                onImagePicked: { data in
                    showCamera = false
                    Task { await viewModel.handleImagePicked(data) }
                },
                onCancel: {
                    showCamera = false
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showBrandPicker) {
            BrandPickerSheet(
                selectedBrand: $viewModel.brand,
                brands: viewModel.availableBrands
            )
            .presentationDetents([.medium, .large])
        }
        .alert("Acceso a la cámara denegado", isPresented: $showCameraPermissionAlert) {
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Para hacer fotos, permite el acceso a la cámara en Ajustes > ClosetSocial.")
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
            .disabled(viewModel.isSaving || viewModel.imageUpload.isUploading)
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
        let upload = viewModel.imageUpload

        return Button {
            guard !upload.isUploading else { return }
            if upload.isFailed {
                Task { await viewModel.retryImageUpload() }
            } else {
                showSourcePicker = true
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(DSColor.imagePlaceholder)

                if let data = upload.localData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity.animation(.easeIn(duration: 0.22)))
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

                if upload.isUploading {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.30))
                    VStack(spacing: 8) {
                        ProgressView().tint(.white).scaleEffect(1.1)
                        Text("Subiendo…")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                } else if upload.isFailed {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(.white)
                        Text("Error al subir · Reintentar")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.90))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                if !upload.isUploading && !upload.isFailed {
                    HStack(spacing: 5) {
                        Image(systemName: upload.hasImage ? "arrow.triangle.2.circlepath.camera.fill" : "camera.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(upload.hasImage ? "Cambiar" : "Galería o cámara")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(DSColor.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DSColor.surface.opacity(0.88), in: Capsule())
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)
                    .padding(12)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Fields

    private var fieldsSection: some View {
        VStack(spacing: 14) {
            AppInputField(
                label: "Nombre",
                text: $viewModel.name,
                isFocused: focusedField == .name,
                submitLabel: .next,
                onSubmit: { focusedField = .color }
            )
            .focused($focusedField, equals: .name)

            AppInputField(
                label: "Color",
                text: $viewModel.color,
                isFocused: focusedField == .color,
                submitLabel: .done,
                onSubmit: { focusedField = nil }
            )
            .focused($focusedField, equals: .color)

            brandRow
        }
    }

    private var brandRow: some View {
        Button {
            focusedField = nil
            showBrandPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Marca")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(DSColor.tertiaryText)
                    Text(viewModel.brand.isEmpty ? "Sin especificar" : viewModel.brand)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(viewModel.brand.isEmpty ? DSColor.tertiaryText : DSColor.primaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DSColor.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(DSColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Category / type section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tipo de prenda")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(DSColor.tertiaryText)
                .padding(.leading, 4)

            if viewModel.isLoadingCatalog {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Cargando tipos…")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(DSColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
            } else if let error = viewModel.catalogLoadError {
                VStack(alignment: .leading, spacing: 10) {
                    AppErrorBanner(error)
                    Button("Reintentar") {
                        Task { await viewModel.loadGarmentTypes() }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(DSColor.accent)
                    .buttonStyle(.plain)
                }
            } else if viewModel.availableCategories.isEmpty {
                Text("No hay categorías disponibles.")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(DSColor.secondaryText)
                    .padding(.horizontal, 6)
            } else {
                categoryChips
                if !viewModel.availableTypes.isEmpty {
                    subtypeGrid
                }
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.availableCategories) { category in
                    CategoryChip(
                        title: category.name,
                        isSelected: viewModel.selectedCategory?.id == category.id
                    ) {
                        if viewModel.selectedCategory?.id == category.id {
                            viewModel.selectedCategory = nil
                        } else {
                            viewModel.selectedCategory = category
                            if !category.subtypes.contains(viewModel.type) {
                                viewModel.type = category.subtypes.first ?? viewModel.type
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var subtypeGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
            spacing: 10
        ) {
            ForEach(viewModel.availableTypes) { type in
                TypeChip(
                    title: type.displayName,
                    isSelected: viewModel.type == type
                ) {
                    viewModel.type = type
                }
            }
        }
    }

    // MARK: Camera permission

    private func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted { showCamera = true }
                    else { showCameraPermissionAlert = true }
                }
            }
        default:
            showCameraPermissionAlert = true
        }
    }
}

// MARK: - Focus fields

private enum GarmentField {
    case name, color
}

// MARK: - Category chip

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? DSColor.actionPrimaryForeground : DSColor.secondaryText)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? DSColor.actionPrimaryBackground : DSColor.surface,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isSelected)
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
                        : DSColor.secondaryText
                )
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected
                        ? DSColor.primaryText
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
