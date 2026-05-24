import SwiftUI

enum AppTypography {
    static let display = Font.system(size: 40, weight: .bold)
    static let headline = Font.system(size: 24, weight: .semibold)
    static let headlineSm = Font.system(size: 20, weight: .semibold)
    static let body = Font.system(size: 14, weight: .regular)
    static let labelCaps = Font.system(size: 12, weight: .semibold)
    static let dataMono = Font.system(size: 18, weight: .medium, design: .monospaced)
    static let caption = Font.system(size: 11, weight: .regular)
    static let metricValue = Font.system(size: 24, weight: .bold)
    static let metricLabel = Font.system(size: 10, weight: .medium)

    /// -0.02em at 40pt
    static let displayTracking: CGFloat = -0.8
    /// -0.01em at 24pt
    static let headlineTracking: CGFloat = -0.24
    /// -0.01em at 20pt
    static let headlineSmTracking: CGFloat = -0.2
}

extension View {
    func labelCapsStyle(color: Color = AppTheme.Colors.onSurfaceSecondary) -> some View {
        font(AppTypography.labelCaps)
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    func displayStyle(color: Color = AppTheme.Colors.onSurface) -> some View {
        font(AppTypography.display)
            .tracking(AppTypography.displayTracking)
            .foregroundStyle(color)
    }

    func headlineStyle(color: Color = AppTheme.Colors.onSurface) -> some View {
        font(AppTypography.headline)
            .tracking(AppTypography.headlineTracking)
            .foregroundStyle(color)
    }

    func headlineSmStyle(color: Color = AppTheme.Colors.onSurface) -> some View {
        font(AppTypography.headlineSm)
            .tracking(AppTypography.headlineSmTracking)
            .foregroundStyle(color)
    }
}
