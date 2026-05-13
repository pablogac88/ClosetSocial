import SwiftUI
import UIKit

public struct LoginView: View {
    @Bindable private var viewModel: LoginViewModel

    public init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            VStack(alignment: .leading, spacing: 10) {
                Text("ClosetSocial")
                    .font(DSFont.largeTitle)
                    .foregroundStyle(DSColor.primaryText)

                Text("Tu red social para compartir compras, armario y outfits con tu gente.")
                    .font(DSFont.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Modo", selection: $viewModel.mode) {
                ForEach(AuthMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 14) {
                if viewModel.mode == .register {
                    inputField("Usuario", text: $viewModel.username, contentType: .username)
                    inputField("Nombre visible", text: $viewModel.displayName, contentType: .name)
                }

                inputField("Email", text: $viewModel.email, contentType: .emailAddress, keyboard: .emailAddress)

                SecureField("Contraseña", text: $viewModel.password)
                    .textContentType(.password)
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(
                title: viewModel.submitTitle,
                isLoading: viewModel.isSubmitting,
                isEnabled: !viewModel.isSubmitDisabled
            ) {
                Task { await viewModel.submit() }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Demo backend")
                    .font(DSFont.footnoteBold)
                    .foregroundStyle(.secondary)

                Text("Usuario: pablo@closetsocial.app")
                Text("Contraseña: password123")
            }
            .font(DSFont.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer()
        }
        .padding(24)
    }

    private func inputField(
        _ title: String,
        text: Binding<String>,
        contentType: UITextContentType,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(contentType)
            .keyboardType(keyboard)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
