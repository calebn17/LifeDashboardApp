import SwiftUI

struct RecoveryCard: View {
    let healthToday: DailyHealthResponse?
    let error: DashboardError?

    private var score: Int? { healthToday?.recovery.score }
    private var progress: Double {
        guard let score else { return 0 }
        return Double(score) / 100.0
    }

    private var statusTitle: String {
        guard let score else { return "—" }
        switch score {
        case 67...: return "Optimized"
        case 34..<67: return "Moderate"
        default: return "Low"
        }
    }

    private var statusSubtitle: String {
        guard let score else { return "No data" }
        switch score {
        case 67...: return "Ready for strain"
        case 34..<67: return "Monitor exertion"
        default: return "Prioritize recovery"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("WHOOP RECOVERY")
                .labelCapsStyle()

            if let error {
                Text(error.localizedDescription)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            } else if let score {
                HStack {
                    RingGauge(
                        value: "\(score)",
                        subtitle: "Score",
                        progress: progress,
                        color: AppTheme.Colors.accentGreen,
                        size: 100
                    )
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(statusTitle)
                            .headlineSmStyle()
                        Text(statusSubtitle)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                    }
                    Spacer()
                }
            } else {
                Text("No recovery data")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            }
        }
        .glassCard()
    }
}
