import XCTest
@testable import LifeDashboard

final class APIClientTests: XCTestCase {

    private var session: URLSession?
    private var client: APIClient?

    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let testSession = URLSession(configuration: config)
        session = testSession
        client = APIClient(
            baseURL: URL(string: "http://localhost:9999")!,
            authToken: "test-token",
            session: testSession,
            keyDecodingStrategy: .convertFromSnakeCase
        )
    }

    private func requireClient() -> APIClient {
        guard let client else {
            XCTFail("APIClient not configured")
            fatalError("APIClient not configured")
        }
        return client
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
    }

    func testSuccessfulDecode() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            let data = """
            {"status": "healthy"}
            """.data(using: .utf8)!
            return (response, data)
        }

        let result: HealthCheckResponse = try await requireClient().get(path: "/health")
        XCTAssertEqual(result.status, "healthy")
    }

    func testUnauthorizedThrows() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 401,
                httpVersion: nil, headerFields: nil
            )!
            return (response, Data())
        }

        do {
            let _: HealthCheckResponse = try await requireClient().get(path: "/test")
            XCTFail("Expected APIError.unauthorized")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Expected APIError, got \(error)")
        }
    }

    func testRateLimitedThrows() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 429,
                httpVersion: nil, headerFields: nil
            )!
            return (response, Data())
        }

        do {
            let _: HealthCheckResponse = try await requireClient().get(path: "/test")
            XCTFail("Expected APIError.rateLimited")
        } catch let error as APIError {
            XCTAssertEqual(error, .rateLimited)
        } catch {
            XCTFail("Expected APIError, got \(error)")
        }
    }

    func testQueryItemsAppended() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url!.absoluteString.contains("period=week"))
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            let data = """
            {"status": "ok"}
            """.data(using: .utf8)!
            return (response, data)
        }

        let _: HealthCheckResponse = try await requireClient().get(
            path: "/test",
            queryItems: [URLQueryItem(name: "period", value: "week")]
        )
    }

    func testBackendUnavailableMapsConnectionErrors() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.cannotConnectToHost)
        }

        do {
            let _: HealthCheckResponse = try await requireClient().get(path: "/health")
            XCTFail("Expected APIError.backendUnavailable")
        } catch let error as APIError {
            XCTAssertEqual(error, .backendUnavailable)
        } catch {
            XCTFail("Expected APIError, got \(error)")
        }
    }
}
