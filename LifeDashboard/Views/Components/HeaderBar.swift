import SwiftUI

struct HeaderBar: View {
    let title: String
    let lastRefreshed: Date?
    let isLoading: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(title)
                .headlineSmStyle()

            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                Text("Search metrics...")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .frame(maxWidth: 320)
            .background(AppTheme.Colors.surface)
            .clipShape(Capsule())

            Spacer()

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if let lastRefreshed {
                Text(lastRefreshed.formatted(.relative(presentation: .named)))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                Circle()
                    .fill(AppTheme.Colors.accentGreen)
                    .frame(width: 8, height: 8)
                Text("SYSTEMS OPTIMIZED")
                    .labelCapsStyle(color: AppTheme.Colors.accentGreen)
            }

            Image(systemName: "bell")
                .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                .accessibilityLabel("Notifications")

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .keyboardShortcut("r", modifiers: .command)
            .accessibilityLabel("Refresh")

            Image(systemName: "person.circle")
                .font(.system(size: 22))
                .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                .accessibilityLabel("Account")
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .frame(height: 64)
        .background {
            AppTheme.Colors.background
                .opacity(0.85)
                .background(.ultraThinMaterial)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
    }
}
