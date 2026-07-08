import SwiftUI
import AppKit

@main
struct QuickCalendarApp: App {
    init() {
        LoginItem.migrateFromLegacyLaunchAgent()
    }

    var body: some Scene {
        MenuBarExtra {
            CalendarView()
        } label: {
            Image(nsImage: Self.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }

    /// メニューバーアイコン（バンドル内の icon.png / icon@2x.png を合成）
    private static let menuBarIcon: NSImage = {
        let img = NSImage(size: NSSize(width: 22, height: 22))
        for name in ["icon", "icon@2x"] {
            if let path = Bundle.main.path(forResource: name, ofType: "png"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let rep = NSBitmapImageRep(data: data) {
                img.addRepresentation(rep)
            }
        }
        guard !img.representations.isEmpty else {
            let fallback = NSImage(
                systemSymbolName: "calendar",
                accessibilityDescription: "Quick Calendar")!
            fallback.isTemplate = true
            return fallback
        }
        img.isTemplate = true
        return img
    }()
}
