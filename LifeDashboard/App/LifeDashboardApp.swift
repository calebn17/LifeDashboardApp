import SwiftUI

@main
struct LifeDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowResizability(.contentMinSize)
    }
}
