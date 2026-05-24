import SwiftUI

struct FitnessView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                RunPerformanceCard(
                    activities: viewModel.recentActivities,
                    summary: viewModel.activitySummary,
                    error: viewModel.errors.first { $0.id == "fitness" }
                )

                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("RECENT ACTIVITIES")
                        .labelCapsStyle()

                    if viewModel.recentActivities.isEmpty {
                        Text("No activities available")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                    } else {
                        ForEach(viewModel.recentActivities) { activity in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(activity.sportType)
                                        .font(AppTypography.body)
                                        .foregroundStyle(AppTheme.Colors.onSurface)
                                    Text(String(activity.startDateLocal.prefix(10)))
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                                }
                                Spacer()
                                Text(String(format: "%.1f mi", activity.distanceMiles))
                                    .font(AppTypography.dataMono)
                                    .foregroundStyle(AppTheme.Colors.accentGreen)
                            }
                            if activity.id != viewModel.recentActivities.last?.id {
                                Divider().opacity(0.2)
                            }
                        }
                    }
                }
                .glassCard()
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
    }
}
