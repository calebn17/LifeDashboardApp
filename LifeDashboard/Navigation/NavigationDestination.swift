import Foundation

enum NavigationDestination: String, CaseIterable, Identifiable {
    case dashboard
    case investments
    case fitness
    case recovery
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .investments: return "Investments"
        case .fitness: return "Fitness"
        case .recovery: return "Recovery"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .investments: return "chart.line.uptrend.xyaxis"
        case .fitness: return "figure.run"
        case .recovery: return "heart.fill"
        case .settings: return "gearshape"
        }
    }
}
