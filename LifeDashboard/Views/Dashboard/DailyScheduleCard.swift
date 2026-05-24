import SwiftUI

struct DailyScheduleCard: View {
    private struct ScheduleEntry: Identifiable {
        let id = UUID()
        let time: String
        let title: String
        let color: Color
    }

    private let entries: [ScheduleEntry] = [
        ScheduleEntry(time: "9:00 AM", title: "Morning Run", color: AppTheme.Colors.accentGreen),
        ScheduleEntry(time: "11:30 AM", title: "Portfolio Review", color: AppTheme.Colors.accentBlue),
        ScheduleEntry(time: "2:00 PM", title: "Deep Work Block", color: AppTheme.Colors.accentGreen)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("DAILY SCHEDULE")
                        .labelCapsStyle()
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(entry.color)
                                    .frame(width: 10, height: 10)
                                if index < entries.count - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 2, height: 32)
                                }
                            }
                            .frame(width: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.time)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                                Text(entry.title)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppTheme.Colors.onSurface)
                            }
                        }
                    }
                }
            }
        .glassCard()
    }
}
