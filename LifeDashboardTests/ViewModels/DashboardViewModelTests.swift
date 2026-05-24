import XCTest
@testable import LifeDashboard

@MainActor
final class DashboardViewModelTests: XCTestCase {

    func testRefreshPopulatesAllDomainsOnSuccess() async {
        let vault = MockVaultAPIProviding()
        let fitness = MockFitnessAPIProviding()
        let viewModel = DashboardViewModel(vaultClient: vault, fitnessClient: fitness)

        await viewModel.refresh()

        XCTAssertNotNil(viewModel.vaultDashboard)
        XCTAssertNotNil(viewModel.fireProjection)
        XCTAssertEqual(viewModel.recentActivities.count, 1)
        XCTAssertNotNil(viewModel.activitySummary)
        XCTAssertNotNil(viewModel.healthToday)
        XCTAssertTrue(viewModel.errors.isEmpty)
        XCTAssertNotNil(viewModel.lastRefreshed)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testVaultFailureLeavesFitnessAndHealthPopulated() async {
        let vault = MockVaultAPIProviding(shouldFail: true)
        let fitness = MockFitnessAPIProviding()
        let viewModel = DashboardViewModel(vaultClient: vault, fitnessClient: fitness)

        await viewModel.refresh()

        XCTAssertNil(viewModel.vaultDashboard)
        XCTAssertNil(viewModel.fireProjection)
        XCTAssertEqual(viewModel.recentActivities.count, 1)
        XCTAssertNotNil(viewModel.healthToday)
        XCTAssertEqual(viewModel.errors.map(\.id), ["vault"])
        XCTAssertFalse(viewModel.isLoading)
    }

    func testFitnessFailureLeavesVaultAndHealthPopulated() async {
        let vault = MockVaultAPIProviding()
        let fitness = MockFitnessAPIProviding(failActivities: true)
        let viewModel = DashboardViewModel(vaultClient: vault, fitnessClient: fitness)

        await viewModel.refresh()

        XCTAssertNotNil(viewModel.vaultDashboard)
        XCTAssertTrue(viewModel.recentActivities.isEmpty)
        XCTAssertNil(viewModel.activitySummary)
        XCTAssertNotNil(viewModel.healthToday)
        XCTAssertEqual(viewModel.errors.map(\.id), ["fitness"])
    }

    func testHealthFailureLeavesVaultAndFitnessPopulated() async {
        let vault = MockVaultAPIProviding()
        let fitness = MockFitnessAPIProviding(failHealth: true)
        let viewModel = DashboardViewModel(vaultClient: vault, fitnessClient: fitness)

        await viewModel.refresh()

        XCTAssertNotNil(viewModel.vaultDashboard)
        XCTAssertEqual(viewModel.recentActivities.count, 1)
        XCTAssertNil(viewModel.healthToday)
        XCTAssertEqual(viewModel.errors.map(\.id), ["health"])
    }

    func testBothClientsFailingRecordsErrorsAndClearsLoading() async {
        let vault = MockVaultAPIProviding(shouldFail: true)
        let fitness = MockFitnessAPIProviding(failActivities: true, failHealth: true)
        let viewModel = DashboardViewModel(vaultClient: vault, fitnessClient: fitness)

        await viewModel.refresh()

        XCTAssertEqual(Set(viewModel.errors.map(\.id)), Set(["vault", "fitness", "health"]))
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.lastRefreshed)
    }

    func testLastRefreshedUpdatesAfterRefresh() async {
        let viewModel = DashboardViewModel(
            vaultClient: MockVaultAPIProviding(),
            fitnessClient: MockFitnessAPIProviding()
        )
        XCTAssertNil(viewModel.lastRefreshed)

        await viewModel.refresh()

        XCTAssertNotNil(viewModel.lastRefreshed)
    }
}

// MARK: - Mocks

private struct MockVaultAPIProviding: VaultAPIProviding {
    var shouldFail = false

    func getDashboard() async throws -> VaultDashboardResponse {
        if shouldFail { throw APIError.backendUnavailable }
        return DashboardTestFixtures.dashboard
    }

    func getFireProjection() async throws -> FIREProjectionResponse {
        if shouldFail { throw APIError.backendUnavailable }
        return DashboardTestFixtures.fireProjection
    }
}

private struct MockFitnessAPIProviding: FitnessAPIProviding {
    var failActivities = false
    var failHealth = false

    func getRecentActivities(limit: Int) async throws -> ActivitiesRecentResponse {
        if failActivities { throw APIError.backendUnavailable }
        return ActivitiesRecentResponse(activities: [DashboardTestFixtures.activity], syncedAt: nil)
    }

    func getActivitySummary(period: String) async throws -> ActivitySummaryResponse {
        if failActivities { throw APIError.backendUnavailable }
        return DashboardTestFixtures.activitySummary
    }

    func getHealthToday() async throws -> DailyHealthResponse {
        if failHealth { throw APIError.backendUnavailable }
        return DashboardTestFixtures.dailyHealth
    }
}

private enum DashboardTestFixtures {
    static let dashboard = VaultDashboardResponse(
        totalNetWorth: 150_000,
        categoryTotals: CategoryTotals(
            crypto: 25_000,
            stocks: 60_000,
            cash: 15_000,
            realEstate: 0,
            retirement: 50_000
        ),
        groupedHoldings: [:]
    )

    static let fireProjection = FIREProjectionResponse(
        status: "reachable",
        unreachableReason: nil,
        inputs: FIREProjectionInputs(
            currentAge: 28,
            annualIncome: 120_000,
            annualExpenses: 60_000,
            currentNetWorth: 150_000,
            targetRetirementAge: 45
        ),
        allocation: nil,
        blendedReturn: 0.08,
        realBlendedReturn: nil,
        inflationRate: nil,
        annualSavings: 60_000,
        savingsRate: 0.5,
        fireTargets: FIRETargets(
            leanFire: FIRETarget(targetAmount: 900_000, yearsToTarget: 10, targetAge: 38),
            fire: FIRETarget(targetAmount: 1_500_000, yearsToTarget: 14, targetAge: 42),
            fatFire: FIRETarget(targetAmount: 3_000_000, yearsToTarget: 20, targetAge: 48)
        ),
        projectionCurve: [ProjectionPoint(age: 28, year: 2026, projectedValue: 150_000)],
        monthlyBreakdown: MonthlyBreakdown(monthlySurplus: 5_000, monthsToFire: 168),
        goalAssessment: GoalAssessment(
            targetAge: 45,
            requiredSavingsRate: 0.4,
            currentSavingsRate: 0.5,
            status: "ahead",
            gapAmount: 0,
            computedBeyondProjectionHorizon: false
        )
    )

    static let activity = Activity(
        id: "activity-1",
        stravaId: 1,
        sportType: "Run",
        startDateLocal: "2026-05-20T07:30:00",
        distanceMeters: 8_046.72,
        movingTimeSeconds: 2_400,
        elapsedTimeSeconds: 2_500,
        averageSpeedMps: 3.35,
        maxSpeedMps: 4.0,
        totalElevationGainMeters: 45,
        averageHeartrate: 155,
        maxHeartrate: 175,
        averageCadence: 170,
        calories: 480,
        prCount: 0,
        distanceMiles: 5.0,
        paceMinPerMile: 8.0
    )

    static let activitySummary = ActivitySummaryResponse(
        period: "week",
        startDate: "2026-05-13",
        endDate: "2026-05-20",
        totalRuns: 4,
        totalDistanceMiles: 22.5,
        totalMovingTimeSeconds: 10_800,
        averagePaceMinPerMile: 8.0,
        totalElevationGainFeet: 580,
        totalCalories: 2_100,
        streakDays: 3,
        syncedAt: nil
    )

    static let dailyHealth = DailyHealthResponse(
        date: "2026-05-20",
        provider: "whoop",
        sleep: SleepData(
            score: 85,
            totalSleepSeconds: 28_800,
            deepSleepSeconds: 7_200,
            remSleepSeconds: 5_400,
            lightSleepSeconds: 16_200,
            efficiency: 92.5
        ),
        recovery: RecoveryData(score: 78, restingHeartRate: 52, hrv: 45, spo2: 97.5),
        strain: StrainData(score: 65, activeCalories: 450, totalCalories: 2_200, steps: nil),
        syncedAt: nil
    )
}
