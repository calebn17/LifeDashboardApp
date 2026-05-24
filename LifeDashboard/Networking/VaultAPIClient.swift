import Foundation

final class VaultAPIClient: Sendable {
    private let client: APIClient

    init(session: URLSession = .shared) {
        self.client = APIClient(
            baseURL: APIConfiguration.Vault.baseURL,
            authToken: APIConfiguration.Vault.authToken,
            session: session,
            keyDecodingStrategy: .useDefaultKeys
        )
    }

    func getDashboard() async throws -> VaultDashboardResponse {
        try await client.get(path: "/api/v1/dashboard")
    }

    func getNetWorthHistory(period: String = "daily") async throws -> NetWorthHistoryResponse {
        try await client.get(
            path: "/api/v1/networth/history",
            queryItems: [URLQueryItem(name: "period", value: period)]
        )
    }

    func getFireProfile() async throws -> FIREProfileResponse {
        try await client.get(path: "/api/v1/fire/profile")
    }

    func getFireProjection() async throws -> FIREProjectionResponse {
        try await client.get(path: "/api/v1/fire/projection")
    }
}
