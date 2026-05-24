import SwiftUI

@main
struct LifeDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Life Dashboard")
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowResizability(.contentMinSize)
    }
}
