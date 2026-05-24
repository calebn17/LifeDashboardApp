import Foundation

final class FitnessAPIClient: Sendable {
    private let client: APIClient

    init(session: URLSession = .shared) {
        self.client = APIClient(
            baseURL: APIConfiguration.Fitness.baseURL,
            authToken: APIConfiguration.Fitness.authToken,
            session: session,
            keyDecodingStrategy: .convertFromSnakeCase
        )
    }

    func checkHealth() async throws -> HealthCheckResponse {
        try await client.get(path: "/health")
    }

    func getRecentActivities(limit: Int = 10) async throws -> ActivitiesRecentResponse {
        try await client.get(
            path: "/api/v1/activities/recent",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
    }

    func getActivitySummary(period: String = "week") async throws -> ActivitySummaryResponse {
        try await client.get(
            path: "/api/v1/activities/summary",
            queryItems: [URLQueryItem(name: "period", value: period)]
        )
    }

    func getHealthToday() async throws -> DailyHealthResponse {
        try await client.get(path: "/api/v1/health/today")
    }

    func getHealthRecent(days: Int = 7) async throws -> HealthRecentResponse {
        try await client.get(
            path: "/api/v1/health/recent",
            queryItems: [URLQueryItem(name: "days", value: String(days))]
        )
    }

    func getHealthSummary(days: Int = 30) async throws -> HealthSummaryResponse {
        try await client.get(
            path: "/api/v1/health/summary",
            queryItems: [URLQueryItem(name: "days", value: String(days))]
        )
    }
}
