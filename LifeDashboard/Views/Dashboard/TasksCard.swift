import SwiftUI

struct TasksCard: View {
    @ObservedObject var localState: CockpitLocalState

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("TODAY'S TASKS")
                    .labelCapsStyle()
                Spacer()
                Image(systemName: "checklist")
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                taskRow(title: "Review weekly training load", isDone: $localState.taskOneDone)
                taskRow(title: "Rebalance portfolio allocation", isDone: $localState.taskTwoDone)
                taskRow(title: "Plan tomorrow deep work block", isDone: $localState.taskThreeDone)
            }
        }
        .glassCard()
    }

    private func taskRow(title: String, isDone: Binding<Bool>) -> some View {
        Button {
            isDone.wrappedValue.toggle()
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: isDone.wrappedValue ? "checkmark.square.fill" : "square")
                    .foregroundStyle(
                        isDone.wrappedValue ? AppTheme.Colors.accentGreen : AppTheme.Colors.onSurfaceSecondary
                    )
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(
                        isDone.wrappedValue
                            ? AppTheme.Colors.onSurfaceSecondary
                            : AppTheme.Colors.onSurface
                    )
                    .strikethrough(isDone.wrappedValue)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
