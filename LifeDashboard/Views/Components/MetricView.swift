import SwiftUI

struct MetricView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTypography.metricLabel)
                .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            Text(value)
                .font(AppTypography.dataMono)
                .foregroundStyle(AppTheme.Colors.onSurface)
        }
    }
}
