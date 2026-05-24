import SwiftUI

struct NetWorthCard: View {
    let dashboard: VaultDashboardResponse?
    let fireProjection: FIREProjectionResponse?
    let error: DashboardError?

    private var projectionCurveValues: [Double] {
        guard let curve = fireProjection?.projectionCurve, !curve.isEmpty else { return [] }
        return curve.map(\.projectedValue)
    }

    private var quarterChangePercent: Double? {
        let values = projectionCurveValues
        guard values.count >= 2, let first = values.first, first > 0 else { return nil }
        let last = values[values.count - 1]
        return ((last - first) / first) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("TOTAL NET WORTH")
                .labelCapsStyle()

            if let error {
                Text(error.localizedDescription)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            } else if let dashboard {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text(dashboard.totalNetWorth, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .displayStyle()

                        if let quarterChangePercent {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                Image(systemName: quarterChangePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                                Text(String(format: "%+.1f%% VS LAST QUARTER", quarterChangePercent))
                            }
                            .font(AppTypography.labelCaps)
                            .foregroundStyle(
                                quarterChangePercent >= 0
                                    ? AppTheme.Colors.accentGreen
                                    : AppTheme.Colors.onSurfaceSecondary
                            )
                        }
                    }

                    Spacer()

                    HStack(spacing: AppTheme.Spacing.lg) {
                        allocationMetric(
                            title: "INVESTMENTS",
                            value: dashboard.categoryTotals.stocks
                                + dashboard.categoryTotals.crypto
                                + dashboard.categoryTotals.retirement
                        )
                        allocationMetric(
                            title: "CASH",
                            value: dashboard.categoryTotals.cash
                        )
                    }
                }

                if !projectionCurveValues.isEmpty {
                    SparklineChart(values: projectionCurveValues, accentColor: AppTheme.Colors.accentGreen)
                }
            } else {
                Text("No portfolio data")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            }
        }
        .glassCard()
    }

    private func allocationMetric(title: String, value: Double) -> some View {
        VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .labelCapsStyle()
            Text(value, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(AppTypography.dataMono)
                .foregroundStyle(AppTheme.Colors.onSurface)
        }
    }
}
