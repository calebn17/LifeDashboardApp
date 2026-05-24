import Combine
import Foundation

enum DashboardError: Identifiable {
    case vault(Error)
    case fitness(Error)
    case health(Error)

    var id: String {
        switch self {
        case .vault: return "vault"
        case .fitness: return "fitness"
        case .health: return "health"
        }
    }

    var localizedDescription: String {
        switch self {
        case .vault(let error): return "Investments: \(error.localizedDescription)"
        case .fitness(let error): return "Fitness: \(error.localizedDescription)"
        case .health(let error): return "Health: \(error.localizedDescription)"
        }
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var vaultDashboard: VaultDashboardResponse?
    @Published var fireProjection: FIREProjectionResponse?
    @Published var recentActivities: [Activity] = []
    @Published var activitySummary: ActivitySummaryResponse?
    @Published var healthToday: DailyHealthResponse?

    @Published var isLoading = false
    @Published var errors: [DashboardError] = []
    @Published var lastRefreshed: Date?

    private let vaultClient: any VaultAPIProviding
    private let fitnessClient: any FitnessAPIProviding

    init(
        vaultClient: any VaultAPIProviding = VaultAPIClient(),
        fitnessClient: any FitnessAPIProviding = FitnessAPIClient()
    ) {
        self.vaultClient = vaultClient
        self.fitnessClient = fitnessClient
    }

    func refresh() async {
        isLoading = true
        errors = []

        async let vaultErrors = fetchVault()
        async let fitnessErrors = fetchFitness()

        let (vault, fitness) = await (vaultErrors, fitnessErrors)
        errors = vault + fitness

        lastRefreshed = Date()
        isLoading = false
    }

    private func fetchVault() async -> [DashboardError] {
        do {
            async let dashboard = vaultClient.getDashboard()
            async let projection = vaultClient.getFireProjection()
            let (dashboardResponse, projectionResponse) = try await (dashboard, projection)
            vaultDashboard = dashboardResponse
            fireProjection = projectionResponse
            return []
        } catch {
            return [.vault(error)]
        }
    }

    private func fetchFitness() async -> [DashboardError] {
        async let activityErrors = fetchFitnessActivities()
        async let healthErrors = fetchHealth()
        let (activity, health) = await (activityErrors, healthErrors)
        return activity + health
    }

    private func fetchFitnessActivities() async -> [DashboardError] {
        do {
            async let activities = fitnessClient.getRecentActivities(limit: 5)
            async let summary = fitnessClient.getActivitySummary(period: "week")
            let (recent, weekSummary) = try await (activities, summary)
            recentActivities = recent.activities
            activitySummary = weekSummary
            return []
        } catch {
            return [.fitness(error)]
        }
    }

    private func fetchHealth() async -> [DashboardError] {
        do {
            healthToday = try await fitnessClient.getHealthToday()
            return []
        } catch {
            return [.health(error)]
        }
    }
}
