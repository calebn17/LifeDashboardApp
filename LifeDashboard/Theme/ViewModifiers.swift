import SwiftUI

struct GlassCardModifier: ViewModifier {
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(AppTheme.Colors.cardBackground)
                    .background(.ultraThinMaterial.opacity(0.3))
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.cardBorderStart,
                                AppTheme.Colors.cardBorderEnd
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

extension View {
    func glassCard(padding: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(padding: padding))
    }
}
