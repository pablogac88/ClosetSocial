import SwiftUI
import UIKit

public struct LoginView: View {
    @Bindable private var viewModel: LoginViewModel
    @FocusState private var focusedField: AuthField?
    @Namespace private var toggleNamespace
    private let onBack: (@MainActor () -> Void)?

    public init(viewModel: LoginViewModel, onBack: (@MainActor () -> Void)? = nil) {
        self.viewModel = viewModel
        self.onBack = onBack
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 60)

                header
                    .padding(.bottom, 52)

                modeToggle
                    .padding(.bottom, 28)

                fieldsSection
                    .padding(.bottom, 12)

                if let error = viewModel.errorMessage {
                    errorBanner(error)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                PrimaryButton(
                    title: viewModel.submitTitle,
                    isLoading: viewModel.isSubmitting,
                    isEnabled: !viewModel.isSubmitDisabled
                ) {
                    Task { await viewModel.submit() }
                }
                .padding(.bottom, 40)

                Spacer(minLength: 20)

                devHint
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 28)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: viewModel.mode)
            .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            Color(red: 0.975, green: 0.970, blue: 0.962)
                .ignoresSafeArea()
        )
        .overlay(alignment: .topLeading) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.40, green: 0.35, blue: 0.31))
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.85), in: Circle())
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                }
                .padding(.leading, 20)
                .padding(.top, 8)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ClosetSocial")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.10, green: 0.08, blue: 0.07))

            Text("Viste tu historia.")
                .font(.system(.title3, design: .rounded, weight: .regular))
                .foregroundStyle(Color(red: 0.56, green: 0.50, blue: 0.46))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Mode toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach(AuthMode.allCases) { mode in
                Button {
                    viewModel.mode = mode
                    viewModel.errorMessage = nil
                } label: {
                    VStack(spacing: 6) {
                        Text(mode.title)
                            .font(.system(.subheadline, design: .rounded, weight: viewModel.mode == mode ? .semibold : .regular))
                            .foregroundStyle(
                                viewModel.mode == mode
                                    ? Color(red: 0.14, green: 0.11, blue: 0.09)
                                    : Color(red: 0.60, green: 0.54, blue: 0.50)
                            )
                            .animation(.none, value: viewModel.mode)

                        ZStack {
                            Rectangle()
                                .frame(height: 2)
                                .foregroundStyle(Color.clear)

                            if viewModel.mode == mode {
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundStyle(DSColor.highlight)
                                    .matchedGeometryEffect(id: "tab_underline", in: toggleNamespace)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color(red: 0.85, green: 0.82, blue: 0.78))
        }
    }

    // MARK: Fields

    private var fieldsSection: some View {
        VStack(spacing: 14) {
            if viewModel.mode == .register {
                AuthInputField(
                    label: "Usuario",
                    text: $viewModel.username,
                    contentType: .username,
                    isFocused: focusedField == .username,
                    submitLabel: .next,
                    onSubmit: { focusedField = .displayName }
                )
                .focused($focusedField, equals: .username)
                .transition(.move(edge: .top).combined(with: .opacity))

                AuthInputField(
                    label: "Nombre visible",
                    text: $viewModel.displayName,
                    contentType: .name,
                    isFocused: focusedField == .displayName,
                    submitLabel: .next,
                    onSubmit: { focusedField = .email }
                )
                .focused($focusedField, equals: .displayName)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            AuthInputField(
                label: "Email",
                text: $viewModel.email,
                contentType: .emailAddress,
                keyboardType: .emailAddress,
                isFocused: focusedField == .email,
                submitLabel: .next,
                onSubmit: { focusedField = .password }
            )
            .focused($focusedField, equals: .email)

            AuthInputField(
                label: "Contraseña",
                text: $viewModel.password,
                contentType: .password,
                isSecure: true,
                isFocused: focusedField == .password,
                submitLabel: .go,
                onSubmit: {
                    focusedField = nil
                    if !viewModel.isSubmitDisabled {
                        Task { await viewModel.submit() }
                    }
                }
            )
            .focused($focusedField, equals: .password)
        }
    }

    // MARK: Error banner

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

    // MARK: Dev hint

    private var devHint: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12, weight: .medium))
                Text("Demo")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(Color(red: 0.60, green: 0.54, blue: 0.50))

            Text("pablo@closetsocial.app  ·  password123")
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(Color(red: 0.68, green: 0.62, blue: 0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color.white.opacity(0.55),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }
}

// MARK: - Focus fields

private enum AuthField {
    case username, displayName, email, password
}

// MARK: - Auth input field

private struct AuthInputField: View {
    let label: String
    @Binding var text: String
    var contentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var isFocused: Bool = false
    var submitLabel: SubmitLabel = .next
    var onSubmit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(
                    isFocused
                        ? DSColor.highlight
                        : Color(red: 0.62, green: 0.56, blue: 0.52)
                )
                .animation(.easeInOut(duration: 0.15), value: isFocused)

            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(keyboardType)
                }
            }
            .textContentType(contentType)
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
                        isFocused ? DSColor.highlight.opacity(0.5) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isFocused
                    ? DSColor.highlight.opacity(0.12)
                    : Color.black.opacity(0.04),
                radius: isFocused ? 8 : 4,
                x: 0,
                y: 2
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}
