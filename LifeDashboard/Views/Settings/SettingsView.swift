import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("API ENDPOINTS")
                        .labelCapsStyle()
                    settingsRow(
                        label: "FitnessTracker",
                        value: APIConfiguration.Fitness.baseURL.absoluteString
                    )
                    settingsRow(
                        label: "VaultTracker",
                        value: APIConfiguration.Vault.baseURL.absoluteString
                    )
                }
                .glassCard()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("ABOUT")
                        .labelCapsStyle()
                    settingsRow(label: "App", value: "Life Intelligence Cockpit")
                    settingsRow(label: "Version", value: "1.0.0 (UI Revamp)")
                    settingsRow(label: "Platform", value: "macOS 14+")
                }
                .glassCard()
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
    }

    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.dataMono)
                .foregroundStyle(AppTheme.Colors.onSurface)
        }
    }
}
