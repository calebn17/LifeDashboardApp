import Combine
import Foundation

/// Local UI state for dashboard widgets that must survive sidebar tab switches.
@MainActor
final class CockpitLocalState: ObservableObject {
    // Deep work timer
    @Published var timeRemaining = 25 * 60
    @Published var isRunning = false

    // Today's tasks
    @Published var taskOneDone = false
    @Published var taskTwoDone = true
    @Published var taskThreeDone = false
}
