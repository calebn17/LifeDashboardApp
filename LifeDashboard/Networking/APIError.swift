import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidResponse
    case unauthorized
    case rateLimited
    case httpError(statusCode: Int)
    case backendUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .unauthorized:
            return "Authentication failed. Check your auth token."
        case .rateLimited:
            return "Too many requests. Try again shortly."
        case .httpError(let code):
            return "Server returned error (HTTP \(code))."
        case .backendUnavailable:
            return "Backend is not running or unreachable."
        }
    }
}
