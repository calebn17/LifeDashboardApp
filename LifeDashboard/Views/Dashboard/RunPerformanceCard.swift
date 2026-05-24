import SwiftUI

struct RunPerformanceCard: View {
    let activities: [Activity]
    let summary: ActivitySummaryResponse?
    let error: DashboardError?

    private let weeklyGoalMiles: Double = 25

    private var weeklyProgress: Double {
        guard let miles = summary?.totalDistanceMiles else { return 0 }
        return min(miles / weeklyGoalMiles, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("RECENT RUN PERFORMANCE")
                    .labelCapsStyle()

                if let error {
                    Text(error.localizedDescription)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                } else if let latest = activities.first {
                    HStack(spacing: AppTheme.Spacing.md) {
                        metricBox(
                            label: "Distance",
                            value: String(format: "%.1f mi", latest.distanceMiles)
                        )
                        metricBox(
                            label: "Duration",
                            value: formatDuration(seconds: latest.movingTimeSeconds)
                        )
                        metricBox(
                            label: "Avg Pace",
                            value: latest.paceMinPerMile.map {
                                String(format: "%.1f min/mi", $0)
                            } ?? "—"
                        )
                    }

                    if let summary {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            HStack {
                                Text("Weekly Goal Progress")
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppTheme.Colors.onSurface)
                                Spacer()
                                Text(String(format: "%.0f%%", weeklyProgress * 100))
                                    .font(AppTypography.dataMono)
                                    .foregroundStyle(AppTheme.Colors.accentGreen)
                            }
                            Text(
                                String(
                                    format: "%.1f / %.0f miles this week",
                                    summary.totalDistanceMiles,
                                    weeklyGoalMiles
                                )
                            )
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                            ProgressBarView(progress: weeklyProgress, accentColor: AppTheme.Colors.accentGreen)
                        }
                    }
                } else {
                    Text("No recent activities")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                }
            }
        .glassCard()
    }

    private func metricBox(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            Text(value)
                .font(AppTypography.dataMono)
                .foregroundStyle(AppTheme.Colors.onSurface)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button))
    }

    private func formatDuration(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
