import AppKit

/// メニューバーアイコンの合成（カレンダー枠 + 今日の日付）
enum MenuBarIcon {
    /// カレンダー枠のグリフ（icon.png / icon@2x.png を合成）
    private static let baseIcon: NSImage = {
        let img = NSImage(size: NSSize(width: 22, height: 22))
        for name in ["icon", "icon@2x"] {
            if let path = Bundle.main.path(forResource: name, ofType: "png"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let rep = NSBitmapImageRep(data: data) {
                img.addRepresentation(rep)
            }
        }
        return img
    }()

    /// 枠の中央に日付を描き込んだテンプレート画像を返す
    static func image(day: Int) -> NSImage {
        let img = NSImage(size: NSSize(width: 22, height: 22),
                          flipped: false) { rect in
            baseIcon.draw(in: rect)

            let font = NSFont.systemFont(ofSize: 10, weight: .bold)
            let text = NSAttributedString(string: "\(day)", attributes: [
                .font: font,
                .foregroundColor: NSColor.black,
            ])
            let size = text.size()
            // 枠内の空きスペース（ヘッダー帯の下）の中央: x=11.5, y=8.6
            text.draw(at: NSPoint(x: 11.5 - size.width / 2,
                                  y: 8.6 - size.height / 2))
            return true
        }
        img.isTemplate = true

        guard !baseIcon.representations.isEmpty else {
            // 枠画像が読めない場合（開発時のswift run等）はSF Symbolで代替
            let fallback = NSImage(
                systemSymbolName: "calendar",
                accessibilityDescription: "Quick Calendar")!
            fallback.isTemplate = true
            return fallback
        }
        return img
    }
}
