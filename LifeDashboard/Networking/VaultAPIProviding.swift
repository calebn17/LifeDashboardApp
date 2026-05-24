import Foundation

protocol VaultAPIProviding: Sendable {
    func getDashboard() async throws -> VaultDashboardResponse
    func getFireProjection() async throws -> FIREProjectionResponse
}

extension VaultAPIClient: VaultAPIProviding {}
