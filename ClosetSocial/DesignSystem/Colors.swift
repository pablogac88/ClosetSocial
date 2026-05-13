import SwiftUI

public enum DSColor {
    public static let primaryText = Color(red: 0.12, green: 0.16, blue: 0.24)
    public static let secondaryText = Color(red: 0.18, green: 0.20, blue: 0.27)
    public static let accent = Color(red: 0.22, green: 0.34, blue: 0.94)
    public static let accentSoft = Color(red: 0.22, green: 0.34, blue: 0.94).opacity(0.12)
    public static let accentDeep = Color(red: 0.20, green: 0.32, blue: 0.96)
    public static let accentDeepSoft = Color(red: 0.20, green: 0.32, blue: 0.96).opacity(0.12)
    public static let highlight = Color(red: 0.25, green: 0.30, blue: 0.58)
    public static let highlightSoft = Color(red: 0.27, green: 0.31, blue: 0.58)
    public static let pillBackground = Color(red: 0.92, green: 0.95, blue: 1.00)

    public static let backgroundGradient: [Color] = [
        Color(red: 0.97, green: 0.97, blue: 0.99),
        Color(red: 0.93, green: 0.95, blue: 0.98),
        Color(red: 0.91, green: 0.94, blue: 0.98)
    ]

    public static let primaryButtonGradient: [Color] = [
        Color(red: 0.19, green: 0.31, blue: 0.95),
        Color(red: 0.46, green: 0.29, blue: 0.96)
    ]
}
