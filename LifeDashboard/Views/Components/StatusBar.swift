import SwiftUI

struct StatusBar: View {
    let lastRefreshed: Date?
    let isLoading: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                Text("Refreshing...")
                    .foregroundStyle(.secondary)
            } else if let date = lastRefreshed {
                Text("Last updated \(date.formatted(.relative(presentation: .named)))")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(isLoading)
            .keyboardShortcut("r", modifiers: .command)
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
