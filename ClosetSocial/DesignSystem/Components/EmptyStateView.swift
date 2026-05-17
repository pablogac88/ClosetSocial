import SwiftUI

public struct EmptyStateView: View {
    public struct Action {
        public let label: String
        public let handler: @MainActor () -> Void

        public init(label: String, handler: @escaping @MainActor () -> Void) {
            self.label = label
            self.handler = handler
        }
    }

    let icon: String
    let title: String
    let message: String
    var action: Action? = nil

    public init(
        icon: String,
        title: String,
        message: String,
        action: Action? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(DSColor.warmFill.opacity(0.8))
                        .frame(width: 84, height: 84)

                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(DSColor.secondaryText)
                }

                VStack(spacing: 10) {
                    Text(title)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(DSColor.primaryText)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(DSFont.body)
                        .foregroundStyle(DSColor.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                if let action {
                    Button(action: action.handler) {
                        Text(action.label)
                            .font(DSFont.footnoteBold)
                            .foregroundStyle(DSColor.highlight)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 13)
                            .background(DSColor.pillBackground, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 44)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
