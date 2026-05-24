import Foundation

enum APIConfiguration {
    enum Fitness {
        static let baseURL = URL(string: "http://localhost:8000")!
        static let authToken = "fitnesstracker-debug-user"
    }

    enum Vault {
        static let baseURL = URL(string: "http://localhost:8001")!
        static let authToken = "vaulttracker-debug-user"
    }
}
