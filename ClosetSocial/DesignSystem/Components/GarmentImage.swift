import SwiftUI

/// Drop-in for AsyncImage in garment contexts.
/// Warm shimmer during loading; fades the image in on success.
/// Caller is responsible for clipping and frame sizing.
struct GarmentImage: View {
    let url: URL?

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                ZStack {
                    ShimmerPlaceholder()
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .transition(.opacity.animation(.easeIn(duration: 0.22)))
                    }
                }
            }
        } else {
            ShimmerPlaceholder()
        }
    }
}

private struct ShimmerPlaceholder: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.93, blue: 0.90)

            GeometryReader { geo in
                LinearGradient(
                    stops: [
                        .init(color: .clear,                    location: 0.00),
                        .init(color: Color.white.opacity(0.42), location: 0.42),
                        .init(color: Color.white.opacity(0.52), location: 0.50),
                        .init(color: Color.white.opacity(0.42), location: 0.58),
                        .init(color: .clear,                    location: 1.00),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width * 3)
                .offset(x: -geo.size.width + phase * geo.size.width * 3)
                .clipped()
            }
            .clipped()
        }
        .onAppear {
            guard phase == 0 else { return }
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}
