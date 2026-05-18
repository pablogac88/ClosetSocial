import SwiftUI

/// Drop-in for AsyncImage in garment contexts.
/// Warm shimmer during loading; fades the image in on success.
/// Shows a styled fallback (not an eternal shimmer) on failure or timeout.
/// Caller is responsible for clipping and frame sizing.
struct GarmentImage: View {
    let url: URL?

    @State private var timedOut = false

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity.animation(.easeIn(duration: 0.22)))

                case .failure(let error):
                    FailurePlaceholder()
                        .onAppear {
                            #if DEBUG
                            print("[GarmentImage] ❌ \(url.absoluteString)\n  → \(error.localizedDescription)")
                            #endif
                        }

                case .empty:
                    if timedOut {
                        FailurePlaceholder()
                    } else {
                        ShimmerPlaceholder()
                    }

                @unknown default:
                    ShimmerPlaceholder()
                }
            }
            .task(id: url) {
                timedOut = false
                try? await Task.sleep(for: .seconds(8))
                timedOut = true
            }
        } else {
            FailurePlaceholder()
        }
    }
}

// MARK: - Failure placeholder

private struct FailurePlaceholder: View {
    var body: some View {
        ZStack {
            DSColor.imagePlaceholder
            Image(systemName: "photo.slash")
                .font(.system(size: 18, weight: .ultraLight))
                .foregroundStyle(DSColor.tertiaryText)
        }
    }
}

// MARK: - Shimmer placeholder

private struct ShimmerPlaceholder: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            DSColor.imagePlaceholder

            GeometryReader { geo in
                LinearGradient(
                    stops: [
                        .init(color: .clear,                        location: 0.00),
                        .init(color: DSColor.surface.opacity(0.42), location: 0.42),
                        .init(color: DSColor.surface.opacity(0.52), location: 0.50),
                        .init(color: DSColor.surface.opacity(0.42), location: 0.58),
                        .init(color: .clear,                        location: 1.00),
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
