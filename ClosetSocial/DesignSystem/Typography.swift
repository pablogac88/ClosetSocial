import SwiftUI

public enum DSFont {
    public static let largeTitle = Font.system(size: 34, weight: .black, design: .rounded)
    public static let title = Font.system(size: 28, weight: .black, design: .rounded)
    public static let headline = Font.system(.headline, design: .rounded, weight: .bold)
    public static let body = Font.system(.body, design: .rounded, weight: .medium)
    public static let footnote = Font.system(.footnote, design: .rounded, weight: .medium)
    public static let footnoteBold = Font.system(.footnote, design: .rounded, weight: .semibold)
    public static let caption = Font.system(.caption, design: .rounded, weight: .medium)
    public static let metric = Font.system(size: 24, weight: .black, design: .rounded)
    public static let avatar = Font.system(size: 28, weight: .black, design: .rounded)
}
