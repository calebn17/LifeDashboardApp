import SwiftUI

struct FitnessPanel: View {
    let activities: [Activity]
    let summary: ActivitySummaryResponse?
    let error: DashboardError?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Fitness", systemImage: "figure.run")
                    .font(.headline)
                    .foregroundStyle(.blue)

                if let error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if activities.isEmpty && summary == nil {
                    Text("No recent activities")
                        .foregroundStyle(.secondary)
                } else {
                    if let latest = activities.first {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latest Run")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 16) {
                                MetricView(
                                    label: "Distance",
                                    value: String(format: "%.1f mi", latest.distanceMiles)
                                )
                                MetricView(
                                    label: "Pace",
                                    value: latest.paceMinPerMile.map {
                                        String(format: "%.1f min/mi", $0)
                                    } ?? "—"
                                )
                                MetricView(
                                    label: "Date",
                                    value: String(latest.startDateLocal.prefix(10))
                                )
                            }
                        }
                        Divider()
                    }

                    if let summary {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("This Week")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 16) {
                                MetricView(
                                    label: "Total Miles",
                                    value: String(format: "%.1f", summary.totalDistanceMiles)
                                )
                                MetricView(
                                    label: "Runs",
                                    value: "\(summary.totalRuns)"
                                )
                                MetricView(
                                    label: "Avg Pace",
                                    value: summary.averagePaceMinPerMile.map {
                                        String(format: "%.1f", $0)
                                    } ?? "—"
                                )
                                MetricView(
                                    label: "Streak",
                                    value: "\(summary.streakDays)d"
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
