import SwiftUI

struct DeepWorkTimerCard: View {
    @ObservedObject var localState: CockpitLocalState

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var formattedTime: String {
        let minutes = localState.timeRemaining / 60
        let seconds = localState.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                    .fill(AppTheme.Colors.accentBlue.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: "timer")
                    .foregroundStyle(AppTheme.Colors.accentBlue)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Deep Work Timer")
                    .headlineSmStyle()
                Text(localState.isRunning ? "Focus session in progress" : "Ready to start")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            }

            Spacer()

            Text(formattedTime)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.accentBlue)

            Button {
                localState.isRunning.toggle()
            } label: {
                Image(systemName: localState.isRunning ? "pause.fill" : "play.fill")
                    .foregroundStyle(AppTheme.Colors.onSurface)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.Colors.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .glassCard()
        .onReceive(timer) { _ in
            guard localState.isRunning, localState.timeRemaining > 0 else { return }
            localState.timeRemaining -= 1
        }
    }
}
