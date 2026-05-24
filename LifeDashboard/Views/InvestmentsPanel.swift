import SwiftUI

struct InvestmentsPanel: View {
    let dashboard: VaultDashboardResponse?
    let fireProjection: FIREProjectionResponse?
    let error: DashboardError?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Investments", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundStyle(.green)

                if let error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if let data = dashboard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net Worth")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(data.totalNetWorth, format: .currency(code: "USD"))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Allocation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 16) {
                            CategoryPill(name: "Stocks", value: data.categoryTotals.stocks)
                            CategoryPill(name: "Crypto", value: data.categoryTotals.crypto)
                            CategoryPill(name: "Cash", value: data.categoryTotals.cash)
                            CategoryPill(name: "Retirement", value: data.categoryTotals.retirement)
                        }
                    }

                    if let fire = fireProjection {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FIRE Progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 16) {
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
                    }
                } else {
                    Text("No portfolio data")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct CategoryPill: View {
    let name: String
    let value: Double

    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
        }
    }
}
