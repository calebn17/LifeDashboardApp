import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.titlebarAppearsTransparent = true
            view.window?.titleVisibility = .hidden
            view.window?.isMovableByWindowBackground = true
            view.window?.backgroundColor = .black
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
