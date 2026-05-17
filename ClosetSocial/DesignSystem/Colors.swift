import SwiftUI
import UIKit

// MARK: - Adaptive colour helper

private extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

// MARK: - DSColor

public enum DSColor {

    // ── Backgrounds ──────────────────────────────────────────────────────────

    /// Main screen background — ivory in light, deep warm-dark in dark.
    public static let background = Color(
        light: UIColor(red: 0.975, green: 0.970, blue: 0.962, alpha: 1),
        dark:  UIColor(red: 0.118, green: 0.102, blue: 0.090, alpha: 1)
    )

    /// Card / sheet surface — white in light, elevated warm-dark in dark.
    public static let surface = Color(
        light: UIColor(red: 1.00,  green: 1.00,  blue: 1.00,  alpha: 1),
        dark:  UIColor(red: 0.165, green: 0.141, blue: 0.125, alpha: 1)
    )

    /// Slightly elevated surface (nested cards, picker rows).
    public static let surfaceElevated = Color(
        light: UIColor(red: 0.975, green: 0.970, blue: 0.962, alpha: 1),
        dark:  UIColor(red: 0.200, green: 0.180, blue: 0.162, alpha: 1)
    )

    /// Image / garment placeholder shimmer base.
    public static let imagePlaceholder = Color(
        light: UIColor(red: 0.945, green: 0.938, blue: 0.922, alpha: 1),
        dark:  UIColor(red: 0.200, green: 0.180, blue: 0.162, alpha: 1)
    )

    // ── Text ─────────────────────────────────────────────────────────────────

    /// Main body text.
    public static let primaryText = Color(
        light: UIColor(red: 0.14, green: 0.11, blue: 0.09, alpha: 1),
        dark:  UIColor(red: 0.96, green: 0.93, blue: 0.90, alpha: 1)
    )

    /// Supporting labels, subtitles.
    public static let secondaryText = Color(
        light: UIColor(red: 0.52, green: 0.47, blue: 0.43, alpha: 1),
        dark:  UIColor(red: 0.71, green: 0.66, blue: 0.60, alpha: 1)
    )

    /// Captions, placeholders, metadata.
    public static let tertiaryText = Color(
        light: UIColor(red: 0.68, green: 0.62, blue: 0.56, alpha: 1),
        dark:  UIColor(red: 0.49, green: 0.44, blue: 0.40, alpha: 1)
    )

    // ── Borders & fills ──────────────────────────────────────────────────────

    /// Dividers, outlines, row separators.
    public static let border = Color(
        light: UIColor(red: 0.88, green: 0.84, blue: 0.79, alpha: 1),
        dark:  UIColor(red: 0.26, green: 0.23, blue: 0.20, alpha: 1)
    )

    /// Avatar bubbles, chip backgrounds, warm decorative fills.
    public static let warmFill = Color(
        light: UIColor(red: 0.91, green: 0.87, blue: 0.82, alpha: 1),
        dark:  UIColor(red: 0.27, green: 0.23, blue: 0.20, alpha: 1)
    )

    // ── Accent & highlight ────────────────────────────────────────────────────

    /// Primary indigo accent — slightly brighter in dark for legibility.
    public static let highlight = Color(
        light: UIColor(red: 0.25, green: 0.30, blue: 0.58, alpha: 1),
        dark:  UIColor(red: 0.48, green: 0.54, blue: 0.85, alpha: 1)
    )

    /// Softer indigo for secondary labels / counts.
    public static let highlightSoft = Color(
        light: UIColor(red: 0.27, green: 0.31, blue: 0.58, alpha: 1),
        dark:  UIColor(red: 0.50, green: 0.56, blue: 0.86, alpha: 1)
    )

    // ── Semantic ──────────────────────────────────────────────────────────────

    /// Destructive / error red.
    public static let destructive = Color(red: 0.82, green: 0.25, blue: 0.28)

    /// Success green (notification badge).
    public static let success = Color(red: 0.25, green: 0.58, blue: 0.42)

    // ── Legacy (kept for PrimaryButton gradient & BackgroundGradient) ─────────

    public static let accent = Color(red: 0.22, green: 0.34, blue: 0.94)
    public static let accentSoft = Color(red: 0.22, green: 0.34, blue: 0.94).opacity(0.12)
    public static let accentDeep = Color(red: 0.20, green: 0.32, blue: 0.96)
    public static let accentDeepSoft = Color(red: 0.20, green: 0.32, blue: 0.96).opacity(0.12)
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
