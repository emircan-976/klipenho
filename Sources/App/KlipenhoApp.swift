import SwiftUI
import AppKit

@main
struct KlipenhoApp: App {
    var body: some Scene {
        WindowGroup("Klipenho") {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // macOS penceresini öne getir ve klavye odaklanmasını etkinleştir
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
