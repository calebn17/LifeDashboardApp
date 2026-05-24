import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var localState: CockpitLocalState

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                NetWorthCard(
                    dashboard: viewModel.vaultDashboard,
                    fireProjection: viewModel.fireProjection,
                    error: viewModel.errors.first { $0.id == "vault" }
                )

                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    RunPerformanceCard(
                        activities: viewModel.recentActivities,
                        summary: viewModel.activitySummary,
                        error: viewModel.errors.first { $0.id == "fitness" }
                    )
                    .layoutPriority(7)
                    .frame(maxWidth: .infinity)

                    VStack(spacing: AppTheme.Spacing.md) {
                        RecoveryCard(
                            healthToday: viewModel.healthToday,
                            error: viewModel.errors.first { $0.id == "health" }
                        )
                        SleepCard(
                            healthToday: viewModel.healthToday,
                            error: viewModel.errors.first { $0.id == "health" }
                        )
                    }
                    .layoutPriority(5)
                    .frame(maxWidth: .infinity)
                }

                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    DailyScheduleCard()
                        .layoutPriority(7)
                        .frame(maxWidth: .infinity)
                    TasksCard(localState: localState)
                        .layoutPriority(5)
                        .frame(maxWidth: .infinity)
                }

                DeepWorkTimerCard(localState: localState)
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
    }
}
