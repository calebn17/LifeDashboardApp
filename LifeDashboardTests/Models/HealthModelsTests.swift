import XCTest
@testable import LifeDashboard

final class HealthModelsTests: XCTestCase {

    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }

    func testDecodeDailyHealthResponse() throws {
        let json = """
        {
          "date": "2026-05-20",
          "provider": "whoop",
          "sleep": {
            "score": 85,
            "total_sleep_seconds": 28800,
            "deep_sleep_seconds": 7200,
            "rem_sleep_seconds": 5400,
            "light_sleep_seconds": 16200,
            "efficiency": 92.5
          },
          "recovery": {
            "score": 78,
            "resting_heart_rate": 52.0,
            "hrv": 45.0,
            "spo2": 97.5
          },
          "strain": {
            "score": 65.0,
            "active_calories": 450,
            "total_calories": 2200,
            "steps": null
          },
          "synced_at": null
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(DailyHealthResponse.self, from: json)
        XCTAssertEqual(result.date, "2026-05-20")
        XCTAssertEqual(result.provider, "whoop")
        XCTAssertEqual(result.sleep.score, 85)
        XCTAssertEqual(result.sleep.totalSleepSeconds, 28800)
        XCTAssertEqual(result.sleep.efficiency, 92.5)
        XCTAssertEqual(result.recovery.score, 78)
        XCTAssertEqual(result.recovery.hrv, 45.0)
        XCTAssertEqual(result.strain.score, 65.0)
        XCTAssertEqual(result.strain.activeCalories, 450)
        XCTAssertNil(result.strain.steps)
    }

    func testDecodeHealthRecentResponse() throws {
        let json = """
        {
          "records": [
            {
              "date": "2026-05-20",
              "provider": "whoop",
              "sleep": {"score": 85, "total_sleep_seconds": 28800, "deep_sleep_seconds": null, "rem_sleep_seconds": null, "light_sleep_seconds": null, "efficiency": null},
              "recovery": {"score": 78, "resting_heart_rate": 52.0, "hrv": 45.0, "spo2": null},
              "strain": {"score": 65.0, "active_calories": 450, "total_calories": 2200, "steps": null},
              "synced_at": null
            }
          ],
          "synced_at": null
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(HealthRecentResponse.self, from: json)
        XCTAssertEqual(result.records.count, 1)
        XCTAssertEqual(result.records[0].provider, "whoop")
    }

    func testDecodeHealthSummaryResponse() throws {
        let json = """
        {
          "period_days": 30,
          "actual_days_with_data": 28,
          "provider": "whoop",
          "avg_sleep_score": 82.0,
          "avg_total_sleep_hours": 7.5,
          "avg_recovery_score": 75.0,
          "avg_resting_heart_rate": 54.0,
          "avg_hrv": 42.0,
          "avg_strain_score": 60.0,
          "avg_active_calories": 420.0,
          "synced_at": null
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(HealthSummaryResponse.self, from: json)
        XCTAssertEqual(result.periodDays, 30)
        XCTAssertEqual(result.actualDaysWithData, 28)
        XCTAssertEqual(result.avgSleepScore, 82.0)
        XCTAssertEqual(result.avgHrv, 42.0)
    }
}
