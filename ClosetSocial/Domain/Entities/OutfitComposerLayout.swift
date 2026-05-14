import Foundation

public enum LayoutTemplate: String, Codable, Sendable, Hashable, CaseIterable {
    case single, duo, trio, quad, editorial, grid
}

public struct NormalizedFrame: Codable, Sendable, Hashable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
}

public struct LayoutItem: Codable, Sendable, Hashable {
    public let garmentID: UUID
    public let normalizedFrame: NormalizedFrame
    public let zIndex: Int

    public init(garmentID: UUID, normalizedFrame: NormalizedFrame, zIndex: Int) {
        self.garmentID = garmentID
        self.normalizedFrame = normalizedFrame
        self.zIndex = zIndex
    }
}

public struct OutfitComposerLayout: Codable, Sendable, Hashable {
    public let version: Int
    public let template: LayoutTemplate
    public let items: [LayoutItem]

    public init(version: Int, template: LayoutTemplate, items: [LayoutItem]) {
        self.version = version
        self.template = template
        self.items = items
    }
}
