import SwiftUI
import PhotosUI
import AVFoundation

public struct OutfitComposerView: View {
    @Bindable var viewModel: OutfitComposerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: GarmentType? = nil
    @State private var showSaveSheet    = false
    @State private var showPublishSheet = false

    public init(viewModel: OutfitComposerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            canvas
            pickerArea
            bottomBar
        }
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(DSColor.primaryText.opacity(0.55))
            }
            ToolbarItem(placement: .principal) {
                Text("Compositor")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(DSColor.primaryText.opacity(0.45))
            }
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveOutfitSheet(viewModel: viewModel, onSaved: { dismiss() })
        }
        .sheet(isPresented: $showPublishSheet) {
            PublishOutfitSheet(viewModel: viewModel, onPublished: { dismiss() })
        }
        .task { await viewModel.loadWardrobe() }
    }

    // MARK: Canvas

    private var canvas: some View {
        Color.clear
            .aspectRatio(3 / 4, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(DSColor.background)
                            .shadow(color: .black.opacity(0.07), radius: 22, x: 0, y: 7)
                            .shadow(color: .black.opacity(0.03), radius: 4,  x: 0, y: 1)

                        if let layout = viewModel.currentLayout {
                            canvasItems(layout: layout, geo: geo)
                        } else {
                            canvasEmptyState
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)
    }

    private func canvasItems(layout: OutfitComposerLayout, geo: GeometryProxy) -> some View {
        let W = geo.size.width
        let H = geo.size.height
        let garmentsByID = Dictionary(uniqueKeysWithValues: viewModel.selectedGarments.map { ($0.id, $0) })
        return ForEach(layout.items.sorted { $0.zIndex < $1.zIndex }, id: \.garmentID) { item in
            if let garment = garmentsByID[item.garmentID] {
                let f = item.normalizedFrame
                CanvasGarmentCard(garment: garment) {
                    HapticEngine.impact(.light)
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.74)) {
                        viewModel.removeGarment(garment)
                    }
                }
                .frame(width: f.width * W, height: f.height * H)
                .position(
                    x: (f.x + f.width  / 2) * W,
                    y: (f.y + f.height / 2) * H
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.86).combined(with: .opacity),
                        removal:   .scale(scale: 0.82).combined(with: .opacity)
                    )
                )
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.76), value: viewModel.selectedGarments.map(\.id))
    }

    private var canvasEmptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(DSColor.warmFill.opacity(0.55))
                    .frame(width: 68, height: 68)
                Image(systemName: "hanger")
                    .font(.system(size: 26, weight: .ultraLight))
                    .foregroundStyle(DSColor.secondaryText)
            }
            VStack(spacing: 5) {
                Text("Tu look empieza aquí")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(DSColor.secondaryText)
                Text("Elige prendas abajo para componer")
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(DSColor.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Picker

    private var pickerArea: some View {
        VStack(spacing: 0) {
            DSColor.warmFill.opacity(0.45).frame(height: 0.5)

            if viewModel.isLoadingWardrobe {
                HStack(spacing: 10) {
                    ProgressView().scaleEffect(0.8)
                    Text("Cargando armario…")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).frame(height: 136)
            } else if viewModel.wardrobeGarments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tshirt")
                        .font(.system(size: 22, weight: .ultraLight))
                        .foregroundStyle(Color.secondary.opacity(0.35))
                    Text("Armario vacío")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.55))
                }
                .frame(maxWidth: .infinity).frame(height: 136)
            } else {
                categoryFilter.padding(.top, 14)
                garmentPicker.padding(.top, 10).padding(.bottom, 14)
            }
        }
        .background(DSColor.surface)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                categoryChip(type: nil, label: "Todo")
                ForEach(availableCategories, id: \.self) { type in
                    categoryChip(type: type, label: type.name)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func categoryChip(type: GarmentType?, label: String) -> some View {
        let isActive = selectedCategory == type
        return Button {
            HapticEngine.selection()
            withAnimation(.easeInOut(duration: 0.17)) { selectedCategory = type }
        } label: {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? DSColor.accent : DSColor.tertiaryText)
                .padding(.horizontal, 13).padding(.vertical, 7)
                .background(
                    isActive ? DSColor.accentSoft : DSColor.surfaceElevated,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    private var garmentPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(filteredGarments) { garment in
                    let isDisabled = viewModel.isAtLimit && !viewModel.isSelected(garment)
                    PickerGarmentCard(
                        garment: garment,
                        isSelected: viewModel.isSelected(garment),
                        isDisabled: isDisabled
                    ) {
                        if isDisabled {
                            HapticEngine.notification(.warning)
                        } else {
                            HapticEngine.impact(.light)
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                                viewModel.addGarment(garment)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        let hasSelection = !viewModel.selectedGarments.isEmpty
        let busy = viewModel.isPublishing || viewModel.isSaving
        return VStack(spacing: 0) {
            DSColor.warmFill.opacity(0.45).frame(height: 0.5)
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    if viewModel.selectedGarments.count > 0 {
                        Text("\(viewModel.selectedGarments.count)/\(OutfitComposerViewModel.maxGarments)")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(DSColor.accent)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(DSColor.accentSoft, in: Capsule())
                            .transition(.scale(scale: 0.7).combined(with: .opacity))
                    }
                    ComposerSaveButton(
                        title: "Publicar",
                        loadingTitle: "Publicando…",
                        icon: "sparkles",
                        isLoading: viewModel.isPublishing,
                        isEnabled: hasSelection && !busy
                    ) {
                        showPublishSheet = true
                    }
                }
                if hasSelection {
                    Button {
                        showSaveSheet = true
                    } label: {
                        Text("Guardar sin publicar")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(DSColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .disabled(busy)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.82), value: viewModel.selectedGarments.count)
            .padding(.horizontal, 20).padding(.vertical, 15)
        }
        .background(DSColor.surface)
    }

    // MARK: Helpers

    private var availableCategories: [GarmentType] {
        Array(Set(viewModel.wardrobeGarments.map(\.type))).sorted { $0.name < $1.name }
    }

    private var filteredGarments: [Garment] {
        guard let cat = selectedCategory else { return viewModel.wardrobeGarments }
        return viewModel.wardrobeGarments.filter { $0.type == cat }
    }
}

// MARK: - Canvas garment card

private struct CanvasGarmentCard: View {
    let garment: Garment
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DSColor.surface)
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 5)
                .shadow(color: .black.opacity(0.04), radius: 3,  x: 0, y: 1)

            garmentImage
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(5)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DSColor.secondaryText)
                    .padding(6)
                    .background(Circle().fill(.regularMaterial).shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 1))
            }
            .padding(8)
        }
    }

    @ViewBuilder
    private var garmentImage: some View {
        if garment.imageURL != nil {
            GarmentImage(url: garment.imageURL)
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "hanger")
                .font(.system(size: 20, weight: .ultraLight))
                .foregroundStyle(DSColor.tertiaryText)
            Text(garment.name)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(DSColor.secondaryText)
                .multilineTextAlignment(.center).lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColor.imagePlaceholder)
    }
}

// MARK: - Picker garment card

private struct PickerGarmentCard: View {
    let garment: Garment
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? DSColor.accentSoft : DSColor.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(isSelected ? DSColor.accent.opacity(0.7) : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(isSelected ? 0.0 : 0.04), radius: 4, x: 0, y: 2)

                    if garment.imageURL != nil {
                        GarmentImage(url: garment.imageURL)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    } else {
                        typeIcon
                    }

                    if isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(DSColor.accent.opacity(0.10))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(DSColor.surface, DSColor.accent)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(6)
                    }
                }
                .frame(width: 86, height: 86)

                Text(garment.name)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(isDisabled ? Color.secondary.opacity(0.35) : DSColor.primaryText)
                    .lineLimit(1).frame(width: 86)
            }
        }
        .buttonStyle(SpringScaleButtonStyle())
        .opacity(isDisabled ? 0.38 : 1)
    }

    private var typeIcon: some View {
        Image(systemName: garmentSystemImage(garment.type))
            .font(.system(size: 22, weight: .ultraLight))
            .foregroundStyle(DSColor.tertiaryText)
    }
}

private struct SpringScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

// MARK: - Composer save button

private struct ComposerSaveButton: View {
    var title: String       = "Guardar look"
    var loadingTitle: String = "Guardando…"
    var icon: String        = "checkmark"
    let isLoading: Bool
    let isEnabled: Bool
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.85)
                } else {
                    Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                }
                Text(isLoading ? loadingTitle : title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(
                LinearGradient(
                    colors: isEnabled
                        ? DSColor.primaryButtonGradient
                        : [DSColor.border, DSColor.border],
                    startPoint: .leading, endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Save sheet

private struct SaveOutfitSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: OutfitComposerViewModel
    let onSaved: () -> Void

    @State private var title = ""
    @State private var note  = ""
    @FocusState private var titleFocused: Bool

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isSaving
    }

    var body: some View {
        ZStack {
            DSColor.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    dragHandle
                    VStack(spacing: 30) {
                        header
                        preview
                        garmentHint
                        fields
                        if let error = viewModel.saveError { AppErrorBanner(error) }
                        actions
                    }
                    .padding(.horizontal, 24).padding(.bottom, 32)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents([.fraction(0.82)])
        .presentationCornerRadius(32)
        .onAppear { titleFocused = true }
    }

    private var dragHandle: some View {
        Capsule()
            .fill(DSColor.border.opacity(0.55))
            .frame(width: 36, height: 4)
            .padding(.top, 12).padding(.bottom, 26)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Guardar look")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(DSColor.primaryText)
            Text("Ponle un nombre a este outfit")
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(DSColor.secondaryText)
        }
    }

    private var preview: some View {
        OutfitCanvasView(layout: viewModel.currentLayout, garments: viewModel.selectedGarments)
            .aspectRatio(3/4, contentMode: .fit)
            .frame(width: 130)
            .shadow(color: .black.opacity(0.09), radius: 16, x: 0, y: 6)
    }

    private var garmentHint: some View {
        let count = viewModel.selectedGarments.count
        let label = count == 1 ? "1 prenda" : "\(count) prendas"
        return Text(label)
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(DSColor.tertiaryText)
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(DSColor.border.opacity(0.5).opacity(0.6), in: Capsule())
    }

    private var fields: some View {
        VStack(spacing: 14) {
            SheetInputCard(label: "Título", placeholder: "Mi nuevo look", text: $title)
                .focused($titleFocused)
            SheetInputCard(label: "Nota", placeholder: "Para qué ocasión, inspiración…",
                           text: $note, axis: .vertical, lineLimit: 2...4)
        }
    }

    private var actions: some View {
        VStack(spacing: 14) {
            ComposerSaveButton(isLoading: viewModel.isSaving, isEnabled: canSave) {
                Task {
                    await viewModel.saveOutfit(title: title.trimmedToNil, note: note.trimmedToNil)
                    if viewModel.saveError == nil {
                        HapticEngine.notification(.success)
                        dismiss()   // cierra este sheet
                        onSaved()   // cierra el compositor padre
                    }
                }
            }
            Button { dismiss() } label: {
                Text("Cancelar")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(DSColor.secondaryText)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)
        }
    }
}

// MARK: - Publish sheet

private struct PublishOutfitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: OutfitComposerViewModel
    let onPublished: () -> Void

    @State private var caption = ""
    @State private var title   = ""
    @State private var note    = ""
    @FocusState private var captionFocused: Bool

    @State private var coverPickerItem: PhotosPickerItem?
    @State private var showSourcePicker = false
    @State private var showCamera = false
    @State private var showCameraPermissionAlert = false

    private var canPublish: Bool {
        !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isPublishing
            && !viewModel.coverImageUpload.isUploading
    }

    var body: some View {
        ZStack {
            DSColor.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    dragHandle
                    VStack(spacing: 28) {
                        header
                        coverPhotoSection
                        preview
                        garmentHint
                        fields
                        if let error = viewModel.publishError { AppErrorBanner(error) }
                        if let error = viewModel.coverImageUpload.errorMessage { AppErrorBanner(error) }
                        actions
                    }
                    .padding(.horizontal, 24).padding(.bottom, 32)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents([.fraction(0.92)])
        .presentationCornerRadius(32)
        .onAppear { captionFocused = true }
        .confirmationDialog("Foto de portada", isPresented: $showSourcePicker, titleVisibility: .visible) {
            Button("Galería") { }
                .overlay {
                    PhotosPicker(selection: $coverPickerItem, matching: .images) {
                        Color.clear
                    }
                }
            Button("Cámara") { openCamera() }
            if viewModel.coverImageUpload.hasImage {
                Button("Eliminar portada", role: .destructive) { viewModel.removeCoverImage() }
            }
            Button("Cancelar", role: .cancel) { }
        }
        .alert("Cámara no disponible", isPresented: $showCameraPermissionAlert) {
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Activa el acceso a la cámara en Ajustes > ClosetSocial.")
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(
                onImagePicked: { data in
                    showCamera = false
                    Task { await viewModel.handleCoverImagePicked(data) }
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
        .onChange(of: coverPickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.handleCoverImagePicked(data)
                }
                coverPickerItem = nil
            }
        }
    }

    private var dragHandle: some View {
        Capsule()
            .fill(DSColor.border.opacity(0.55))
            .frame(width: 36, height: 4)
            .padding(.top, 12).padding(.bottom, 26)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Publicar look")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(DSColor.primaryText)
            Text("Comparte este outfit con la comunidad")
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(DSColor.secondaryText)
        }
    }

    @ViewBuilder
    private var coverPhotoSection: some View {
        let upload = viewModel.coverImageUpload
        VStack(alignment: .leading, spacing: 10) {
            Text("Foto de portada")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(DSColor.secondaryText)
                .padding(.horizontal, 2)

            Button { showSourcePicker = true } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DSColor.surfaceElevated)
                        .frame(height: 110)

                    if let data = upload.localData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(alignment: .topTrailing) {
                                if upload.isUploading {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(8)
                                        .background(Circle().fill(.black.opacity(0.45)))
                                        .padding(8)
                                }
                            }
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 22, weight: .light))
                                .foregroundStyle(DSColor.accent)
                            Text("Añadir foto real (opcional)")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(DSColor.secondaryText)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            if upload.isFailed {
                Button {
                    Task { await viewModel.retryCoverImageUpload() }
                } label: {
                    Label("Reintentar subida", systemImage: "arrow.clockwise")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(DSColor.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var preview: some View {
        OutfitCanvasView(layout: viewModel.currentLayout, garments: viewModel.selectedGarments)
            .aspectRatio(3/4, contentMode: .fit)
            .frame(width: 130)
            .shadow(color: .black.opacity(0.09), radius: 16, x: 0, y: 6)
    }

    private var garmentHint: some View {
        let count = viewModel.selectedGarments.count
        let label = count == 1 ? "1 prenda" : "\(count) prendas"
        return Text(label)
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(DSColor.tertiaryText)
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(DSColor.border.opacity(0.5).opacity(0.6), in: Capsule())
    }

    private var fields: some View {
        VStack(spacing: 14) {
            SheetInputCard(label: "Descripción", placeholder: "Describe tu look…",
                           text: $caption, axis: .vertical, lineLimit: 2...4)
                .focused($captionFocused)
            SheetInputCard(label: "Título del outfit", placeholder: "Nombre del look (opcional)", text: $title)
            SheetInputCard(label: "Nota", placeholder: "Para qué ocasión, inspiración…",
                           text: $note, axis: .vertical, lineLimit: 2...4)
        }
    }

    private var actions: some View {
        VStack(spacing: 14) {
            ComposerSaveButton(
                title: "Publicar",
                loadingTitle: "Publicando…",
                icon: "sparkles",
                isLoading: viewModel.isPublishing,
                isEnabled: canPublish
            ) {
                guard canPublish else { return }
                Task {
                    await viewModel.publishOutfit(
                        title: title.trimmedToNil,
                        note: note.trimmedToNil,
                        caption: caption.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    if viewModel.publishError == nil {
                        HapticEngine.notification(.success)
                        dismiss()
                        onPublished()
                    }
                }
            }
            Button { dismiss() } label: {
                Text("Cancelar")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(DSColor.secondaryText)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPublishing)
        }
    }

    private func openCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
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

// MARK: - Sheet input card

private struct SheetInputCard: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int> = 1...1

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(DSColor.secondaryText)
                .padding(.horizontal, 2)
            TextField(placeholder, text: $text, axis: axis)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(DSColor.primaryText)
                .tint(DSColor.accent)
                .lineLimit(axis == .vertical ? lineLimit : 1...1)
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DSColor.surface)
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                )
        }
    }
}

// MARK: - Helpers

private func garmentSystemImage(_ type: GarmentType) -> String {
    switch type.kind {
    case .coat, .jacket, .blazer: return "coat"
    case .shirt, .tShirt, .top:   return "tshirt"
    case .trousers:               return "rectangle.split.2x1"
    case .dress:                  return "figure.dress.line.vertical.figure"
    case .shoes:                  return "shoe"
    case .accessory:              return "sparkle"
    case .other:                  return "hanger"
    }
}

private extension String {
    var trimmedToNil: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
