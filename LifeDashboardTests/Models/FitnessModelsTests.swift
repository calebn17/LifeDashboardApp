import XCTest
@testable import LifeDashboard

final class FitnessModelsTests: XCTestCase {

    private func decoder() -> JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }

    func testDecodeActivitiesRecentResponse() throws {
        let json = """
        {
          "activities": [
            {
              "id": "a1b2c3d4-0000-0000-0000-000000000000",
              "strava_id": 12345678,
              "sport_type": "Run",
              "start_date_local": "2026-05-20T07:30:00",
              "distance_meters": 8046.72,
              "moving_time_seconds": 2400,
              "elapsed_time_seconds": 2500,
              "average_speed_mps": 3.35,
              "max_speed_mps": 4.0,
              "total_elevation_gain_meters": 45.0,
              "average_heartrate": 155.0,
              "max_heartrate": 175.0,
              "average_cadence": 170.0,
              "calories": 480.0,
              "pr_count": 0,
              "distance_miles": 5.0,
              "pace_min_per_mile": 8.0
            }
          ],
          "synced_at": "2026-05-20T08:00:00"
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(ActivitiesRecentResponse.self, from: json)
        XCTAssertEqual(result.activities.count, 1)
        let activity = result.activities[0]
        XCTAssertEqual(activity.stravaId, 12345678)
        XCTAssertEqual(activity.sportType, "Run")
        XCTAssertEqual(activity.distanceMiles, 5.0)
        XCTAssertEqual(activity.paceMinPerMile, 8.0)
    }

    func testDecodeActivitySummaryResponse() throws {
        let json = """
        {
          "period": "week",
          "start_date": "2026-05-13",
          "end_date": "2026-05-20",
          "total_runs": 4,
          "total_distance_miles": 22.5,
          "total_moving_time_seconds": 10800,
          "average_pace_min_per_mile": 8.0,
          "total_elevation_gain_feet": 580.0,
          "total_calories": 2100.0,
          "streak_days": 3,
          "synced_at": null
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(ActivitySummaryResponse.self, from: json)
        XCTAssertEqual(result.period, "week")
        XCTAssertEqual(result.totalRuns, 4)
        XCTAssertEqual(result.totalDistanceMiles, 22.5)
        XCTAssertEqual(result.streakDays, 3)
    }

    func testDecodeHealthCheckResponse() throws {
        let json = """
        {"status": "healthy"}
        """.data(using: .utf8)!

        let result = try decoder().decode(HealthCheckResponse.self, from: json)
        XCTAssertEqual(result.status, "healthy")
    }
}
