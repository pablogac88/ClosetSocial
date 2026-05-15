import SwiftUI

public struct AvatarBubble: View {
    private let displayName: String
    private let avatarURL: URL?
    private let size: CGFloat
    private let fillColor: Color
    private let textColor: Color

    public init(
        displayName: String,
        avatarURL: URL? = nil,
        size: CGFloat = 46,
        fillColor: Color = DSColor.accentSoft,
        textColor: Color = DSColor.accent
    ) {
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.size = size
        self.fillColor = fillColor
        self.textColor = textColor
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: size, height: size)
                .overlay {
                    Text(initials)
                        .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                        .foregroundStyle(textColor)
                }

            if let avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                            .transition(.opacity.animation(.easeIn(duration: 0.22)))
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }

    private var initials: String {
        let words = displayName.split(separator: " ")
        let prefix = words.prefix(2).compactMap(\.first)
        return String(prefix)
    }
}
