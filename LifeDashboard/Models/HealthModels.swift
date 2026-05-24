import Foundation

struct DailyHealthResponse: Codable {
    let date: String
    let provider: String
    let sleep: SleepData
    let recovery: RecoveryData
    let strain: StrainData
    let syncedAt: String?
}

struct SleepData: Codable {
    let score: Int?
    let totalSleepSeconds: Int?
    let deepSleepSeconds: Int?
    let remSleepSeconds: Int?
    let lightSleepSeconds: Int?
    let efficiency: Double?
}

struct RecoveryData: Codable {
    let score: Int?
    let restingHeartRate: Double?
    let hrv: Double?
    let spo2: Double?
}

struct StrainData: Codable {
    let score: Double?
    let activeCalories: Int?
    let totalCalories: Int?
    let steps: Int?
}

struct HealthRecentResponse: Codable {
    let records: [DailyHealthResponse]
    let syncedAt: String?
}

struct HealthSummaryResponse: Codable {
    let periodDays: Int
    let actualDaysWithData: Int
    let provider: String
    let avgSleepScore: Double?
    let avgTotalSleepHours: Double?
    let avgRecoveryScore: Double?
    let avgRestingHeartRate: Double?
    let avgHrv: Double?
    let avgStrainScore: Double?
    let avgActiveCalories: Double?
    let syncedAt: String?
}
