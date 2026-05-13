import SwiftUI

public struct BackgroundGradientView: View {
    public init() {}

    public var body: some View {
        LinearGradient(
            colors: DSColor.backgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
