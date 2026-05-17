import Foundation

public struct OutfitLayoutEngine: Sendable {

    private init() {}

    public static func generateLayout(for garments: [Garment]) -> OutfitComposerLayout {
        let capped = Array(garments.prefix(6))
        guard !capped.isEmpty else {
            return OutfitComposerLayout(version: 1, template: .single, items: [])
        }
        let sorted = sortBySemantic(capped)
        let template = LayoutTemplate.selecting(count: sorted.count)
        let frames = frameTable[sorted.count] ?? []
        let items = zip(sorted, frames).enumerated().map { index, pair -> LayoutItem in
            let (garment, frame) = pair
            return LayoutItem(garmentID: garment.id, normalizedFrame: frame, zIndex: sorted.count - index)
        }
        return OutfitComposerLayout(version: 1, template: template, items: items)
    }

    private static func sortBySemantic(_ garments: [Garment]) -> [Garment] {
        garments
            .enumerated()
            .sorted { lhs, rhs in
                let lp = priority(lhs.element.type)
                let rp = priority(rhs.element.type)
                return lp == rp ? lhs.offset < rhs.offset : lp < rp
            }
            .map(\.element)
    }

    private static func priority(_ type: GarmentType) -> Int {
        switch type.kind {
        case .coat:      return 0
        case .jacket:    return 1
        case .blazer:    return 2
        case .shirt:     return 3
        case .tShirt:    return 4
        case .top:       return 5
        case .dress:     return 6
        case .trousers:  return 7
        case .shoes:     return 8
        case .accessory: return 9
        case .other:     return 10
        }
    }

    private static let frameTable: [Int: [NormalizedFrame]] = [
        1: frames1, 2: frames2, 3: frames3,
        4: frames4, 5: frames5, 6: frames6
    ]

    private static let frames1: [NormalizedFrame] = [
        .init(x: 0.15, y: 0.10, width: 0.70, height: 0.80)
    ]

    private static let frames2: [NormalizedFrame] = [
        .init(x: 0.02, y: 0.03, width: 0.58, height: 0.50),
        .init(x: 0.40, y: 0.46, width: 0.58, height: 0.50)
    ]

    private static let frames3: [NormalizedFrame] = [
        .init(x: 0.02, y: 0.03, width: 0.56, height: 0.48),
        .init(x: 0.42, y: 0.30, width: 0.56, height: 0.48),
        .init(x: 0.14, y: 0.74, width: 0.72, height: 0.24)
    ]

    private static let frames4: [NormalizedFrame] = [
        .init(x: 0.01, y: 0.02, width: 0.48, height: 0.46),
        .init(x: 0.51, y: 0.02, width: 0.48, height: 0.46),
        .init(x: 0.01, y: 0.52, width: 0.48, height: 0.46),
        .init(x: 0.51, y: 0.52, width: 0.48, height: 0.46)
    ]

    private static let frames5: [NormalizedFrame] = [
        .init(x: 0.01, y: 0.02, width: 0.48, height: 0.41),
        .init(x: 0.51, y: 0.02, width: 0.48, height: 0.41),
        .init(x: 0.01, y: 0.46, width: 0.48, height: 0.41),
        .init(x: 0.51, y: 0.46, width: 0.48, height: 0.41),
        .init(x: 0.20, y: 0.88, width: 0.60, height: 0.11)
    ]

    private static let frames6: [NormalizedFrame] = [
        .init(x: 0.01, y: 0.01, width: 0.48, height: 0.35),
        .init(x: 0.51, y: 0.01, width: 0.48, height: 0.35),
        .init(x: 0.01, y: 0.39, width: 0.48, height: 0.35),
        .init(x: 0.51, y: 0.39, width: 0.48, height: 0.35),
        .init(x: 0.01, y: 0.77, width: 0.48, height: 0.22),
        .init(x: 0.51, y: 0.77, width: 0.48, height: 0.22)
    ]
}

extension LayoutTemplate {
    static func selecting(count: Int) -> LayoutTemplate {
        switch count {
        case 1:  return .single
        case 2:  return .duo
        case 3:  return .trio
        case 4:  return .quad
        default: return .editorial
        }
    }
}
