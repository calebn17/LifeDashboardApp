import SwiftUI

struct SidebarView: View {
    @Binding var selection: NavigationDestination

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            logoSection
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xl)

            VStack(spacing: AppTheme.Spacing.xs) {
                ForEach(NavigationDestination.allCases) { destination in
                    sidebarButton(for: destination)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.sm)

            Spacer()

            profileSection
                .padding(AppTheme.Spacing.md)
        }
        .frame(width: 240)
        .background(AppTheme.Colors.background)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)
        }
    }

    private var logoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Life Intelligence")
                .headlineSmStyle()
            Text("PREMIUM COCKPIT")
                .labelCapsStyle(color: AppTheme.Colors.accentGreen.opacity(0.6))
        }
    }

    private func sidebarButton(for destination: NavigationDestination) -> some View {
        let isSelected = selection == destination
        return Button {
            selection = destination
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: destination.icon)
                    .frame(width: 20)
                Text(destination.title)
                    .font(AppTypography.body)
                Spacer()
            }
            .foregroundStyle(isSelected ? AppTheme.Colors.accentGreen : AppTheme.Colors.onSurfaceSecondary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                        .fill(AppTheme.Colors.accentGreen.opacity(0.12))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var profileSection: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(AppTheme.Colors.surface)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                    }
                Circle()
                    .fill(AppTheme.Colors.accentGreen)
                    .frame(width: 10, height: 10)
                    .overlay {
                        Circle()
                            .stroke(AppTheme.Colors.background, lineWidth: 2)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Alex Mercer")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.onSurface)
                Text("PRO ACCESS")
                    .labelCapsStyle(color: AppTheme.Colors.accentGreen.opacity(0.8))
            }
        }
    }
}
