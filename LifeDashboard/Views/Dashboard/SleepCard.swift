import SwiftUI

struct SleepCard: View {
    let healthToday: DailyHealthResponse?
    let error: DashboardError?

    private var score: Int? { healthToday?.sleep.score }
    private var progress: Double {
        guard let score else { return 0 }
        return Double(score) / 100.0
    }

    private var durationText: String {
        guard let seconds = healthToday?.sleep.totalSleepSeconds else { return "—" }
        let hours = Double(seconds) / 3600.0
        return String(format: "%.1fh slept", hours)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("OURA SLEEP")
                    .labelCapsStyle()

                if let error {
                    Text(error.localizedDescription)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                } else if let score {
                    HStack {
                        RingGauge(
                            value: "\(score)",
                            subtitle: "Score",
                            progress: progress,
                            color: AppTheme.Colors.accentBlue,
                            size: 100
                        )
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(score >= 70 ? "Restored" : "Recovering")
                                .headlineSmStyle()
                            Text(durationText)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                        }
                        Spacer()
                    }
                } else {
                    Text("No sleep data")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                }
            }
        .glassCard()
    }
}
