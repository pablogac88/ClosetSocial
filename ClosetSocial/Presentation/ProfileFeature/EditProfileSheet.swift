import SwiftUI
import PhotosUI
import AVFoundation

public struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    public typealias OnSave = (String, String, String) async -> Bool

    private let uploadRepository: any UploadRepository
    private let tokenProvider: @MainActor () -> String?
    private let onSave: OnSave

    @State private var displayName: String
    @State private var bio: String
    @State private var baseAvatarURL: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: EditField?

    @State private var pickerItem: PhotosPickerItem?
    @State private var imageUpload = ImageUploadManager()
    @State private var showSourcePicker = false
    @State private var showGallery = false
    @State private var showCamera = false
    @State private var showCameraPermissionAlert = false

    private let bioLimit = 160

    private var effectiveAvatarURL: String {
        imageUpload.remoteURL?.absoluteString ?? baseAvatarURL
    }

    public init(
        initialDisplayName: String,
        initialBio: String,
        initialAvatarURL: String,
        uploadRepository: any UploadRepository,
        tokenProvider: @escaping @MainActor () -> String?,
        onSave: @escaping OnSave
    ) {
        self._displayName = State(initialValue: initialDisplayName)
        self._bio = State(initialValue: initialBio)
        self._baseAvatarURL = State(initialValue: initialAvatarURL)
        self.uploadRepository = uploadRepository
        self.tokenProvider = tokenProvider
        self.onSave = onSave
    }

    public var body: some View {
        ZStack(alignment: .top) {
            DSColor.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 64)

                    avatarSection
                        .padding(.bottom, 28)

                    fieldsSection
                        .padding(.bottom, 24)

                    if let error = imageUpload.errorMessage {
                        AppErrorBanner(error)
                            .padding(.bottom, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if let error = errorMessage {
                        AppErrorBanner(error)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    PrimaryButton(
                        title: "Guardar cambios",
                        isLoading: isSaving,
                        isEnabled: !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && !imageUpload.isUploading
                    ) {
                        Task { await saveProfile() }
                    }
                    .padding(.bottom, 12)

                    Button("Cancelar") { dismiss() }
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(DSColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .disabled(isSaving || imageUpload.isUploading)

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: errorMessage)
                .animation(.easeInOut(duration: 0.2), value: imageUpload.errorMessage)
            }
            .scrollDismissesKeyboard(.interactively)

            headerBar
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await uploadAvatar(data)
                } else {
                    errorMessage = "No se pudo cargar la imagen seleccionada."
                }
                pickerItem = nil
            }
        }
        .confirmationDialog(
            "Foto de perfil",
            isPresented: $showSourcePicker,
            titleVisibility: .visible
        ) {
            Button("Elegir de galería") { showGallery = true }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Hacer foto") { openCamera() }
            }
            if imageUpload.hasImage || !baseAvatarURL.isEmpty {
                Button("Eliminar foto", role: .destructive) {
                    imageUpload.remove()
                    baseAvatarURL = ""
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
                    Task { await uploadAvatar(data) }
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
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
            Text("Editar perfil")
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
            .disabled(isSaving || imageUpload.isUploading)
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

    // MARK: Avatar section

    private var avatarSection: some View {
        let upload = imageUpload

        return VStack(spacing: 16) {
            Button {
                guard !upload.isUploading else { return }
                if upload.isFailed {
                    Task { await retryAvatarUpload() }
                } else {
                    showSourcePicker = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(DSColor.warmFill)
                        .frame(width: 100, height: 100)

                    if let data = upload.localData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .transition(.opacity.animation(.easeIn(duration: 0.22)))
                    } else if let url = URL(string: baseAvatarURL), !baseAvatarURL.isEmpty {
                        GarmentImage(url: url)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        AvatarBubble(
                            displayName: displayName.isEmpty ? "?" : displayName,
                            size: 100,
                            fillColor: DSColor.warmFill,
                            textColor: DSColor.secondaryText
                        )
                    }

                    if upload.isUploading {
                        Circle()
                            .fill(Color.black.opacity(0.35))
                            .frame(width: 100, height: 100)
                        ProgressView().tint(.white)
                    } else if upload.isFailed {
                        Circle()
                            .fill(Color.black.opacity(0.50))
                            .frame(width: 100, height: 100)
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                            Text("Reintentar")
                                .font(.system(.caption2, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.90))
                        }
                    } else {
                        Circle()
                            .fill(Color.black.opacity(0.18))
                            .frame(width: 100, height: 100)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Fields

    private var fieldsSection: some View {
        VStack(spacing: 14) {
            AppInputField(
                label: "Nombre",
                text: $displayName,
                isFocused: focusedField == .displayName,
                submitLabel: .next,
                onSubmit: { focusedField = .bio }
            )
            .focused($focusedField, equals: .displayName)

            bioField
        }
    }

    private var bioField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bio")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(
                    focusedField == .bio
                        ? DSColor.highlight
                        : DSColor.tertiaryText
                )
                .animation(.easeInOut(duration: 0.15), value: focusedField == .bio)

            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $bio)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(DSColor.primaryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 90, maxHeight: 130)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .padding(.bottom, 22)
                    .background(DSColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                focusedField == .bio
                                    ? DSColor.highlight.opacity(0.5)
                                    : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: focusedField == .bio
                            ? DSColor.highlight.opacity(0.10)
                            : Color.black.opacity(0.04),
                        radius: focusedField == .bio ? 8 : 4,
                        x: 0,
                        y: 2
                    )
                    .focused($focusedField, equals: .bio)
                    .onChange(of: bio) { _, new in
                        if new.count > bioLimit {
                            bio = String(new.prefix(bioLimit))
                        }
                    }

                Text("\(bio.count)/\(bioLimit)")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(
                        bio.count >= bioLimit
                            ? DSColor.destructive
                            : DSColor.tertiaryText
                    )
                    .padding(.trailing, 14)
                    .padding(.bottom, 8)
                    .animation(.none, value: bio.count)
            }
        }
    }

    // MARK: Upload avatar

    private func uploadAvatar(_ data: Data) async {
        guard let token = tokenProvider() else {
            errorMessage = DomainError.unauthenticated.userMessage
            return
        }
        await imageUpload.pick(data, using: uploadRepository, token: token)
    }

    private func retryAvatarUpload() async {
        guard let token = tokenProvider() else { return }
        await imageUpload.retry(using: uploadRepository, token: token)
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

    // MARK: Save

    private func saveProfile() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        let saved = await onSave(
            displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            bio,
            effectiveAvatarURL.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        if saved {
            dismiss()
        } else {
            errorMessage = "No hemos podido guardar los cambios. Inténtalo de nuevo."
        }
    }
}

// MARK: - Focus fields

private enum EditField {
    case displayName, bio
}
