import SwiftUI

struct RingGauge: View {
    let value: String
    let subtitle: String
    let progress: Double
    let color: Color
    var size: CGFloat = 120

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 8)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.4), radius: 8)
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.onSurface)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = min(max(progress, 0), 1)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = min(max(newValue, 0), 1)
            }
        }
    }
}
