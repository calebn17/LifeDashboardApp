import SwiftUI

struct AppNavigation: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var localState = CockpitLocalState()
    @State private var selectedDestination: NavigationDestination = .dashboard

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $selectedDestination)

            VStack(spacing: 0) {
                HeaderBar(
                    title: selectedDestination.title,
                    lastRefreshed: viewModel.lastRefreshed,
                    isLoading: viewModel.isLoading
                ) {
                    Task { await viewModel.refresh() }
                }

                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppTheme.Colors.background)
        }
        .background(AppTheme.Colors.background)
        .preferredColorScheme(.dark)
        .task {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedDestination {
        case .dashboard:
            DashboardView(viewModel: viewModel, localState: localState)
        case .investments:
            InvestmentsView(viewModel: viewModel)
        case .fitness:
            FitnessView(viewModel: viewModel)
        case .recovery:
            RecoveryView(viewModel: viewModel)
        case .settings:
            SettingsView()
        }
    }
}
