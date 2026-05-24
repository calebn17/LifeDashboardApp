import Foundation

struct HealthCheckResponse: Codable {
    let status: String
}

struct ActivitiesRecentResponse: Codable {
    let activities: [Activity]
    let syncedAt: String?
}

struct Activity: Codable, Identifiable {
    let id: String
    let stravaId: Int
    let sportType: String
    let startDateLocal: String
    let distanceMeters: Double
    let movingTimeSeconds: Int
    let elapsedTimeSeconds: Int
    let averageSpeedMps: Double
    let maxSpeedMps: Double?
    let totalElevationGainMeters: Double
    let averageHeartrate: Double?
    let maxHeartrate: Double?
    let averageCadence: Double?
    let calories: Double?
    let prCount: Int
    let distanceMiles: Double
    let paceMinPerMile: Double?
}

struct ActivitySummaryResponse: Codable {
    let period: String
    let startDate: String
    let endDate: String
    let totalRuns: Int
    let totalDistanceMiles: Double
    let totalMovingTimeSeconds: Int
    let averagePaceMinPerMile: Double?
    let totalElevationGainFeet: Double
    let totalCalories: Double?
    let streakDays: Int
    let syncedAt: String?
}
