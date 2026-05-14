import SwiftUI

public struct WelcomeView: View {
    let onGetStarted: @MainActor () -> Void
    let onLogin: @MainActor () -> Void

    public init(
        onGetStarted: @escaping @MainActor () -> Void,
        onLogin: @escaping @MainActor () -> Void
    ) {
        self.onGetStarted = onGetStarted
        self.onLogin = onLogin
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            heroIllustration
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            contentArea
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Hero

    private var heroIllustration: some View {
        ZStack {
            Color(red: 0.955, green: 0.948, blue: 0.930)

            // Garment silhouettes — back row
            garment(w: 52, h: 132, color: Color(red: 0.34, green: 0.30, blue: 0.26))
                .rotationEffect(.degrees(5.5))
                .offset(x: 116, y: -28)

            garment(w: 50, h: 130, color: Color(red: 0.78, green: 0.72, blue: 0.64))
                .rotationEffect(.degrees(-7))
                .offset(x: -114, y: -30)

            // Garment silhouettes — mid row
            garment(w: 60, h: 148, color: Color(red: 0.64, green: 0.58, blue: 0.50))
                .rotationEffect(.degrees(-3.5))
                .offset(x: 62, y: -22)

            garment(w: 60, h: 148, color: Color(red: 0.88, green: 0.83, blue: 0.76))
                .rotationEffect(.degrees(-2.5))
                .offset(x: -58, y: -24)

            // Center garment — front, tallest
            garment(w: 65, h: 155, color: Color(red: 0.93, green: 0.89, blue: 0.82))
                .rotationEffect(.degrees(1.5))
                .offset(x: 2, y: -18)

            // Rod
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.32, green: 0.27, blue: 0.23))
                .frame(width: 260, height: 5)
                .offset(y: -114)

            // Bottom fade to page background
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color(red: 0.975, green: 0.970, blue: 0.962).opacity(0.7), location: 0.55),
                        .init(color: Color(red: 0.975, green: 0.970, blue: 0.962), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
            }
        }
    }

    private func garment(w: CGFloat, h: CGFloat, color: Color) -> some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.55))
                .frame(width: 2, height: 20)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color)
                .frame(width: w, height: h)
                .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 6)
        }
    }

    // MARK: Content

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tu estilo,\ntu historia.")
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundStyle(Color(red: 0.10, green: 0.08, blue: 0.06))
                .lineSpacing(4)
                .padding(.bottom, 14)

            Text("Construye tu armario, crea looks\ny comparte tu estilo.")
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(Color(red: 0.52, green: 0.46, blue: 0.42))
                .padding(.bottom, 36)

            // Primary CTA
            Button(action: onGetStarted) {
                Text("Empezar")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Color(red: 0.10, green: 0.08, blue: 0.07),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)

            // Secondary link
            Button(action: onLogin) {
                Text("Ya tengo cuenta")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(Color(red: 0.40, green: 0.35, blue: 0.31))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.top, 32)
        .padding(.bottom, 48)
        .background(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Color(red: 0.975, green: 0.970, blue: 0.962).opacity(0.96), location: 0.12),
                    .init(color: Color(red: 0.975, green: 0.970, blue: 0.962), location: 0.25),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}
