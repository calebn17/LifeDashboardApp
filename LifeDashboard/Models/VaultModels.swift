import Foundation

struct VaultDashboardResponse: Codable {
    let totalNetWorth: Double
    let categoryTotals: CategoryTotals
    let groupedHoldings: [String: [Holding]]
}

struct CategoryTotals: Codable {
    let crypto: Double
    let stocks: Double
    let cash: Double
    let realEstate: Double
    let retirement: Double
}

struct Holding: Codable, Identifiable {
    let id: String
    let name: String
    let symbol: String?
    let quantity: Double
    let currentValue: Double

    enum CodingKeys: String, CodingKey {
        case id, name, symbol, quantity
        case currentValue = "current_value"
    }
}

struct NetWorthHistoryResponse: Codable {
    let snapshots: [NetWorthSnapshot]
}

struct NetWorthSnapshot: Codable {
    let date: Date
    let value: Double
}

struct FIREProfileResponse: Codable {
    let id: String
    let currentAge: Int
    let annualIncome: Double
    let annualExpenses: Double
    let targetRetirementAge: Int?
    let createdAt: Date
    let updatedAt: Date
}

struct FIREProjectionResponse: Codable {
    let status: String
    let unreachableReason: String?
    let inputs: FIREProjectionInputs
    let allocation: FIREAllocation?
    let blendedReturn: Double?
    let realBlendedReturn: Double?
    let inflationRate: Double?
    let annualSavings: Double?
    let savingsRate: Double?
    let fireTargets: FIRETargets
    let projectionCurve: [ProjectionPoint]
    let monthlyBreakdown: MonthlyBreakdown
    let goalAssessment: GoalAssessment?
}

struct FIREProjectionInputs: Codable {
    let currentAge: Int
    let annualIncome: Double
    let annualExpenses: Double
    let currentNetWorth: Double
    let targetRetirementAge: Int?
}

struct FIREAllocationSlice: Codable {
    let value: Double
    let percentage: Double
    let expectedReturn: Double
}

struct FIREAllocation: Codable {
    let crypto: FIREAllocationSlice
    let stocks: FIREAllocationSlice
    let cash: FIREAllocationSlice
    let realEstate: FIREAllocationSlice
    let retirement: FIREAllocationSlice
}

struct FIRETargets: Codable {
    let leanFire: FIRETarget
    let fire: FIRETarget
    let fatFire: FIRETarget
}

struct FIRETarget: Codable {
    let targetAmount: Double
    let yearsToTarget: Int?
    let targetAge: Int?
}

struct ProjectionPoint: Codable {
    let age: Int
    let year: Int
    let projectedValue: Double
}

struct MonthlyBreakdown: Codable {
    let monthlySurplus: Double
    let monthsToFire: Int?
}

struct GoalAssessment: Codable {
    let targetAge: Int
    let requiredSavingsRate: Double
    let currentSavingsRate: Double
    let status: String
    let gapAmount: Double
    let computedBeyondProjectionHorizon: Bool
}
