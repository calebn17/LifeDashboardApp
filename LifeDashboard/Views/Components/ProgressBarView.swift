import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    let accentColor: Color

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.Colors.surface)
                Capsule()
                    .fill(accentColor)
                    .frame(width: geometry.size.width * animatedProgress)
                    .shadow(color: accentColor.opacity(0.4), radius: 6)
            }
        }
        .frame(height: 8)
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
