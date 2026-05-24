import SwiftUI

struct InvestmentsView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                NetWorthCard(
                    dashboard: viewModel.vaultDashboard,
                    fireProjection: viewModel.fireProjection,
                    error: viewModel.errors.first { $0.id == "vault" }
                )

                if let dashboard = viewModel.vaultDashboard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("ALLOCATION")
                            .labelCapsStyle()
                        HStack(spacing: AppTheme.Spacing.md) {
                            CategoryPill(name: "Stocks", value: dashboard.categoryTotals.stocks)
                            CategoryPill(name: "Crypto", value: dashboard.categoryTotals.crypto)
                            CategoryPill(name: "Cash", value: dashboard.categoryTotals.cash)
                            CategoryPill(name: "Retirement", value: dashboard.categoryTotals.retirement)
                        }
                    }
                    .glassCard()
                }

                if let fire = viewModel.fireProjection {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("FIRE PROGRESS")
                            .labelCapsStyle()
                        HStack(spacing: AppTheme.Spacing.lg) {
                            MetricView(
                                label: "Lean FIRE",
                                value: fire.fireTargets.leanFire.targetAge.map { "Age \($0)" } ?? "—"
                            )
                            MetricView(
                                label: "FIRE",
                                value: fire.fireTargets.fire.targetAge.map { "Age \($0)" } ?? "—"
                            )
                            MetricView(
                                label: "Savings Rate",
                                value: fire.savingsRate.map {
                                    String(format: "%.0f%%", $0 * 100)
                                } ?? "—"
                            )
                            if let assessment = fire.goalAssessment {
                                MetricView(
                                    label: "Status",
                                    value: assessment.status.capitalized
                                )
                            }
                        }
                    }
                    .glassCard()
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
    }
}

struct CategoryPill: View {
    let name: String
    let value: Double

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(name)
                .font(AppTypography.metricLabel)
                .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            Text(value, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(AppTypography.dataMono)
                .foregroundStyle(AppTheme.Colors.onSurface)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button))
    }
}
