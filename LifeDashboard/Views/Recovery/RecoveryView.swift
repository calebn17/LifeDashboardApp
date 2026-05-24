import SwiftUI

struct RecoveryView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                HStack(spacing: AppTheme.Spacing.lg) {
                    recoveryGaugeCard
                    sleepGaugeCard
                }

                if let health = viewModel.healthToday {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("TODAY'S METRICS")
                            .labelCapsStyle()
                        HStack(spacing: AppTheme.Spacing.lg) {
                            if let strain = health.strain.score {
                                MetricView(label: "Strain", value: String(format: "%.1f", strain))
                            }
                            if let calories = health.strain.activeCalories {
                                MetricView(label: "Active Cal", value: "\(calories)")
                            }
                            if let hrv = health.recovery.hrv {
                                MetricView(label: "HRV", value: String(format: "%.0f ms", hrv))
                            }
                            if let rhr = health.recovery.restingHeartRate {
                                MetricView(label: "RHR", value: String(format: "%.0f bpm", rhr))
                            }
                        }
                        Text("Source: \(health.provider.capitalized)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                    }
                    .glassCard()
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
    }

    private var recoveryGaugeCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("RECOVERY")
                .labelCapsStyle()
            if let score = viewModel.healthToday?.recovery.score {
                RingGauge(
                    value: "\(score)",
                    subtitle: "Score",
                    progress: Double(score) / 100.0,
                    color: AppTheme.Colors.accentGreen,
                    size: 160
                )
            } else {
                Text("No recovery data")
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var sleepGaugeCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("SLEEP")
                .labelCapsStyle()
            if let score = viewModel.healthToday?.sleep.score {
                RingGauge(
                    value: "\(score)",
                    subtitle: "Score",
                    progress: Double(score) / 100.0,
                    color: AppTheme.Colors.accentBlue,
                    size: 160
                )
            } else {
                Text("No sleep data")
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}
