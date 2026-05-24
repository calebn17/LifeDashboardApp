import SwiftUI

struct HealthPanel: View {
    let healthToday: DailyHealthResponse?
    let error: DashboardError?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Health", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundStyle(.purple)

                if let error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if let health = healthToday {
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sleep")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let score = health.sleep.score {
                                MetricView(label: "Score", value: "\(score)")
                            }
                            if let total = health.sleep.totalSleepSeconds {
                                let hours = Double(total) / 3600.0
                                MetricView(label: "Duration", value: String(format: "%.1fh", hours))
                            }
                            if let efficiency = health.sleep.efficiency {
                                MetricView(label: "Efficiency", value: String(format: "%.0f%%", efficiency))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recovery")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let score = health.recovery.score {
                                MetricView(label: "Score", value: "\(score)")
                            }
                            if let restingHeartRate = health.recovery.restingHeartRate {
                                MetricView(label: "RHR", value: String(format: "%.0f bpm", restingHeartRate))
                            }
                            if let hrv = health.recovery.hrv {
                                MetricView(label: "HRV", value: String(format: "%.0f ms", hrv))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Strain")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let score = health.strain.score {
                                MetricView(label: "Score", value: String(format: "%.1f", score))
                            }
                            if let calories = health.strain.activeCalories {
                                MetricView(label: "Active Cal", value: "\(calories)")
                            }
                        }
                    }

                    Text("Source: \(health.provider.capitalized)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No health data for today")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
