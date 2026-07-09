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
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}

/// メニューバーのラベル。日付が変わるとアイコンを描き直す
struct MenuBarLabel: View {
    @State private var today = Date()

    var body: some View {
        Image(nsImage: MenuBarIcon.image(
            day: Calendar.current.component(.day, from: today)))
            .onReceive(NotificationCenter.default.publisher(
                for: .NSCalendarDayChanged)) { _ in
                today = Date()
            }
    }
}
