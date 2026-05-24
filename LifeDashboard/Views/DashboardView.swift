import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(
                lastRefreshed: viewModel.lastRefreshed,
                isLoading: viewModel.isLoading
            ) {
                Task { await viewModel.refresh() }
            }

            ScrollView {
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        FitnessPanel(
                            activities: viewModel.recentActivities,
                            summary: viewModel.activitySummary,
                            error: viewModel.errors.first { $0.id == "fitness" }
                        )
                        HealthPanel(
                            healthToday: viewModel.healthToday,
                            error: viewModel.errors.first { $0.id == "health" }
                        )
                    }

                    InvestmentsPanel(
                        dashboard: viewModel.vaultDashboard,
                        fireProjection: viewModel.fireProjection,
                        error: viewModel.errors.first { $0.id == "vault" }
                    )
                }
                .padding(20)
            }
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.07))
        .task {
            await viewModel.refresh()
        }
    }
}
