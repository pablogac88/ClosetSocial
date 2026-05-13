import SwiftUI

public struct AvatarBubble: View {
    private let displayName: String
    private let size: CGFloat
    private let fillColor: Color
    private let textColor: Color

    public init(
        displayName: String,
        size: CGFloat = 46,
        fillColor: Color = DSColor.accentSoft,
        textColor: Color = DSColor.accent
    ) {
        self.displayName = displayName
        self.size = size
        self.fillColor = fillColor
        self.textColor = textColor
    }

    public var body: some View {
        Circle()
            .fill(fillColor)
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
            }
    }

    private var initials: String {
        let words = displayName.split(separator: " ")
        let prefix = words.prefix(2).compactMap(\.first)
        return String(prefix)
    }
}
