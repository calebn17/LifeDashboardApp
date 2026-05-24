import XCTest
@testable import LifeDashboard

final class VaultModelsTests: XCTestCase {

    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func testDecodeDashboardResponse() throws {
        let json = """
        {
          "totalNetWorth": 150000.00,
          "categoryTotals": {
            "crypto": 25000.00,
            "stocks": 60000.00,
            "cash": 15000.00,
            "realEstate": 0.00,
            "retirement": 50000.00
          },
          "groupedHoldings": {
            "crypto": [
              {
                "id": "abc-123",
                "name": "Bitcoin",
                "symbol": "BTC",
                "quantity": 0.5,
                "current_value": 25000.00
              }
            ],
            "stocks": [],
            "cash": [],
            "realEstate": [],
            "retirement": []
          }
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(VaultDashboardResponse.self, from: json)
        XCTAssertEqual(result.totalNetWorth, 150000.00)
        XCTAssertEqual(result.categoryTotals.crypto, 25000.00)
        XCTAssertEqual(result.categoryTotals.realEstate, 0.00)
        XCTAssertEqual(result.groupedHoldings["crypto"]?.count, 1)
        XCTAssertEqual(result.groupedHoldings["crypto"]?.first?.symbol, "BTC")
    }

    func testDecodeNetWorthHistoryResponse() throws {
        let json = """
        {
          "snapshots": [
            {"date": "2026-05-01T00:00:00Z", "value": 148000.00},
            {"date": "2026-05-02T00:00:00Z", "value": 149200.00}
          ]
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(NetWorthHistoryResponse.self, from: json)
        XCTAssertEqual(result.snapshots.count, 2)
        XCTAssertEqual(result.snapshots[0].value, 148000.00)
    }

    func testDecodeFIREProjectionResponse() throws {
        let json = """
        {
          "status": "reachable",
          "unreachableReason": null,
          "inputs": {
            "currentAge": 28,
            "annualIncome": 120000.00,
            "annualExpenses": 60000.00,
            "currentNetWorth": 150000.00,
            "targetRetirementAge": 45
          },
          "allocation": null,
          "blendedReturn": 0.08,
          "realBlendedReturn": null,
          "inflationRate": null,
          "annualSavings": 60000.00,
          "savingsRate": 0.50,
          "fireTargets": {
            "leanFire": {"targetAmount": 900000.00, "yearsToTarget": 10, "targetAge": 38},
            "fire": {"targetAmount": 1500000.00, "yearsToTarget": 14, "targetAge": 42},
            "fatFire": {"targetAmount": 3000000.00, "yearsToTarget": 20, "targetAge": 48}
          },
          "projectionCurve": [
            {"age": 28, "year": 2026, "projectedValue": 150000.00}
          ],
          "monthlyBreakdown": {"monthlySurplus": 5000.00, "monthsToFire": 168},
          "goalAssessment": {
            "targetAge": 45,
            "requiredSavingsRate": 0.40,
            "currentSavingsRate": 0.50,
            "status": "ahead",
            "gapAmount": 0.00,
            "computedBeyondProjectionHorizon": false
          }
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(FIREProjectionResponse.self, from: json)
        XCTAssertEqual(result.status, "reachable")
        XCTAssertEqual(result.savingsRate, 0.50)
        XCTAssertEqual(result.fireTargets.leanFire.targetAge, 38)
        XCTAssertEqual(result.goalAssessment?.status, "ahead")
    }
}
