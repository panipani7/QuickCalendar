import Foundation
import ServiceManagement

/// ログイン時自動起動（SMAppService）
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    /// 旧Python版が作成した LaunchAgent 設定が残っていれば削除し、
    /// SMAppService の登録に引き継ぐ
    static func migrateFromLegacyLaunchAgent() {
        let legacy = NSString(
            string: "~/Library/LaunchAgents/com.local.quickcalendar.plist"
        ).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: legacy) else { return }
        try? FileManager.default.removeItem(atPath: legacy)
        try? SMAppService.mainApp.register()
    }
}
