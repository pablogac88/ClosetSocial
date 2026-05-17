import SwiftUI

public struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let isEnabled: Bool
    private let action: @MainActor () -> Void

    public init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @MainActor @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView().tint(.white)
                }
                Text(title).font(DSFont.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                DSColor.primaryText,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity((!isEnabled || isLoading) ? 0.7 : 1)
    }
}
