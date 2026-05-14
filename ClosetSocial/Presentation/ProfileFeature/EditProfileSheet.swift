import SwiftUI

public struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    public typealias OnSave = (String, String, String) async -> Bool

    private let onSave: OnSave

    @State private var displayName: String
    @State private var bio: String
    @State private var avatarURL: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: EditField?

    private let bioLimit = 160

    public init(
        initialDisplayName: String,
        initialBio: String,
        initialAvatarURL: String,
        onSave: @escaping OnSave
    ) {
        self._displayName = State(initialValue: initialDisplayName)
        self._bio = State(initialValue: initialBio)
        self._avatarURL = State(initialValue: initialAvatarURL)
        self.onSave = onSave
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.975, green: 0.970, blue: 0.962)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 64)

                    avatarSection
                        .padding(.bottom, 28)

                    fieldsSection
                        .padding(.bottom, 24)

                    if let error = errorMessage {
                        errorBanner(error)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    PrimaryButton(
                        title: "Guardar cambios",
                        isLoading: isSaving,
                        isEnabled: !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        Task { await saveProfile() }
                    }
                    .padding(.bottom, 12)

                    Button("Cancelar") { dismiss() }
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Color(red: 0.58, green: 0.52, blue: 0.48))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .disabled(isSaving)

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: errorMessage)
            }
            .scrollDismissesKeyboard(.interactively)

            headerBar
        }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack {
            Text("Editar perfil")
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
            .disabled(isSaving)
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

    // MARK: Avatar section

    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.91, green: 0.87, blue: 0.82))
                    .frame(width: 100, height: 100)

                if let url = avatarPreviewURL {
                    GarmentImage(url: url)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    AvatarBubble(
                        displayName: displayName.isEmpty ? "?" : displayName,
                        size: 100,
                        fillColor: Color(red: 0.91, green: 0.87, blue: 0.82),
                        textColor: Color(red: 0.44, green: 0.38, blue: 0.32)
                    )
                }
            }
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)

            ProfileInputField(
                label: "URL de avatar",
                text: $avatarURL,
                keyboardType: .URL,
                autocapitalization: .never,
                isFocused: focusedField == .avatarURL,
                submitLabel: .next,
                onSubmit: { focusedField = .displayName }
            )
            .focused($focusedField, equals: .avatarURL)
        }
    }

    private var avatarPreviewURL: URL? {
        let trimmed = avatarURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    // MARK: Fields

    private var fieldsSection: some View {
        VStack(spacing: 14) {
            ProfileInputField(
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
                        ? Color(red: 0.25, green: 0.30, blue: 0.58)
                        : Color(red: 0.62, green: 0.56, blue: 0.52)
                )
                .animation(.easeInOut(duration: 0.15), value: focusedField == .bio)

            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $bio)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(Color(red: 0.14, green: 0.11, blue: 0.09))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 90, maxHeight: 130)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .padding(.bottom, 22)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                focusedField == .bio
                                    ? Color(red: 0.25, green: 0.30, blue: 0.58).opacity(0.5)
                                    : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: focusedField == .bio
                            ? Color(red: 0.25, green: 0.30, blue: 0.58).opacity(0.10)
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
                            ? Color(red: 0.72, green: 0.18, blue: 0.18)
                            : Color(red: 0.72, green: 0.66, blue: 0.60)
                    )
                    .padding(.trailing, 14)
                    .padding(.bottom, 8)
                    .animation(.none, value: bio.count)
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

    // MARK: Save

    private func saveProfile() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        let saved = await onSave(
            displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            bio,
            avatarURL.trimmingCharacters(in: .whitespacesAndNewlines)
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
    case avatarURL, displayName, bio
}

// MARK: - Input field

private struct ProfileInputField: View {
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
