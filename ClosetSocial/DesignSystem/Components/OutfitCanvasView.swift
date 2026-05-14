import SwiftUI

/// Non-interactive canvas that renders an OutfitComposerLayout.
/// Fills its container — callers control size via frame / aspectRatio modifiers.
struct OutfitCanvasView: View {
    let layout: OutfitComposerLayout?
    let garments: [Garment]
    var cornerRadius: CGFloat = 18
    var backgroundColor: Color = Color(red: 0.982, green: 0.973, blue: 0.957)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
                if let layout {
                    canvasItems(layout: layout, geo: geo)
                } else {
                    garmentFallback(geo: geo)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func canvasItems(layout: OutfitComposerLayout, geo: GeometryProxy) -> some View {
        let W = geo.size.width
        let H = geo.size.height
        let byID = Dictionary(uniqueKeysWithValues: garments.map { ($0.id, $0) })
        return ForEach(layout.items.sorted { $0.zIndex < $1.zIndex }, id: \.garmentID) { item in
            if let garment = byID[item.garmentID] {
                let f = item.normalizedFrame
                CanvasTile(garment: garment, tileCornerRadius: max(cornerRadius * 0.55, 6))
                    .frame(width: f.width * W, height: f.height * H)
                    .position(x: (f.x + f.width / 2) * W, y: (f.y + f.height / 2) * H)
            }
        }
    }

    // Fallback for outfits without a persisted layout (created via quick form).
    @ViewBuilder
    private func garmentFallback(geo: GeometryProxy) -> some View {
        let cols = min(garments.count, 2)
        let size = cols > 0 ? (geo.size.width - CGFloat(cols + 1) * 8) / CGFloat(cols) : 0
        let rows = Int(ceil(Double(garments.count) / Double(max(cols, 1))))
        VStack(spacing: 8) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<cols, id: \.self) { col in
                        let idx = row * cols + col
                        if idx < garments.count {
                            CanvasTile(garment: garments[idx], tileCornerRadius: 10)
                                .frame(width: size, height: size)
                        }
                    }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct CanvasTile: View {
    let garment: Garment
    var tileCornerRadius: CGFloat = 9

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: tileCornerRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
            GarmentImage(url: garment.imageURL)
                .clipShape(RoundedRectangle(cornerRadius: max(tileCornerRadius - 1.5, 0), style: .continuous))
                .padding(2.5)
        }
    }
}
