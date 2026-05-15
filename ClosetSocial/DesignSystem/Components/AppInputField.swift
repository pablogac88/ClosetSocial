import SwiftUI
import UIKit

public struct AppInputField: View {
    let label: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false
    var isFocused: Bool = false
    var submitLabel: SubmitLabel = .next
    var onSubmit: () -> Void = {}

    public init(
        label: String,
        text: Binding<String>,
        contentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .sentences,
        isSecure: Bool = false,
        isFocused: Bool = false,
        submitLabel: SubmitLabel = .next,
        onSubmit: @escaping () -> Void = {}
    ) {
        self.label = label
        self._text = text
        self.contentType = contentType
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.isSecure = isSecure
        self.isFocused = isFocused
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    public var body: some View {
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
                        .textInputAutocapitalization(autocapitalization)
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
