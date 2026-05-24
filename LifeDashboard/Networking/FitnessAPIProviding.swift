import Foundation

protocol FitnessAPIProviding: Sendable {
    func getRecentActivities(limit: Int) async throws -> ActivitiesRecentResponse
    func getActivitySummary(period: String) async throws -> ActivitySummaryResponse
    func getHealthToday() async throws -> DailyHealthResponse
}

extension FitnessAPIClient: FitnessAPIProviding {}
