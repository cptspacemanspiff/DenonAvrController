import SwiftUI
import AppKit

struct FloatingWindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.level = .floating
            }
        }
        return nsView
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
