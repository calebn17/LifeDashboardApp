import Charts
import SwiftUI

struct SparklineChart: View {
    let values: [Double]
    let accentColor: Color

    var body: some View {
        if values.isEmpty {
            RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                .fill(AppTheme.Colors.surface)
                .frame(height: 80)
                .overlay {
                    Text("No trend data")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.onSurfaceSecondary)
                }
        } else {
            Chart(Array(values.enumerated()), id: \.offset) { index, value in
                AreaMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor.opacity(0.35), accentColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .frame(height: 80)
        }
    }
}
