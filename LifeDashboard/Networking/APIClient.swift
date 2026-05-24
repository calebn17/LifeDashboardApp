import Foundation

final class APIClient: Sendable {
    let baseURL: URL
    private let authToken: String
    private let session: URLSession
    private let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy

    init(
        baseURL: URL,
        authToken: String,
        session: URLSession = .shared,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase
    ) {
        self.baseURL = baseURL
        self.authToken = authToken
        self.session = session
        self.keyDecodingStrategy = keyDecodingStrategy
    }

    func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        guard let url = requestURL(path: path, queryItems: queryItems) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError
            where urlError.code == .cannotConnectToHost
            || urlError.code == .networkConnectionLost
            || urlError.code == .timedOut
        {
            throw APIError.backendUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = keyDecodingStrategy
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.httpError(statusCode: http.statusCode)
        }
    }

    private func requestURL(path: String, queryItems: [URLQueryItem]) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let normalizedPath = path.hasPrefix("/") ? path : "/" + path
        let basePath = components.path == "/" ? "" : components.path
        components.path = basePath + normalizedPath
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url
    }
}
