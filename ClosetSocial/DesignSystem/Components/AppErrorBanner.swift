import SwiftUI

public struct AppErrorBanner: View {
    let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var body: some View {
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
}
