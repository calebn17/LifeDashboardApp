import SwiftUI

@main
struct LifeDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            AppNavigation()
                .frame(minWidth: 1200, minHeight: 800)
                .background(WindowConfigurator())
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1200, height: 800)
    }
}
