import SwiftUI
import AppKit

private let CELL: CGFloat = 36   // 日付セルのサイズ
private let PAD: CGFloat = 14    // 左右パディング
private let VIEW_W = CELL * 7 + PAD * 2

private let WEEKDAYS_JP = ["日", "月", "火", "水", "木", "金", "土"]

private var gregorian: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.firstWeekday = 1  // 日曜始まり
    return cal
}()

struct CalendarView: View {
    @State private var year: Int
    @State private var month: Int
    @State private var today = Date()
    @State private var launchAtLogin = LoginItem.isEnabled

    init() {
        let now = gregorian.dateComponents([.year, .month], from: Date())
        _year = State(initialValue: now.year!)
        _month = State(initialValue: now.month!)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.horizontal, PAD)
            weekdayRow
            calendarGrid
            Divider().padding(.horizontal, PAD)
            footer
        }
        .frame(width: VIEW_W)
        .onAppear {
            today = Date()
            launchAtLogin = LoginItem.isEnabled
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            today = Date()
        }
    }

    // MARK: - ヘッダー（年月 + ナビ）

    private var header: some View {
        HStack {
            Button("‹") { moveMonth(-1) }
                .buttonStyle(.plain)
                .font(.system(size: 20))
            Spacer()
            Text("\(String(year))年 \(month)月")
                .font(.system(size: 14, weight: .bold))
            Spacer()
            Button("›") { moveMonth(1) }
                .buttonStyle(.plain)
                .font(.system(size: 20))
        }
        .padding(.horizontal, PAD + 4)
        .frame(height: 44)
    }

    // MARK: - 曜日行

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                Text(WEEKDAYS_JP[i])
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(weekdayColor(i))
                    .frame(width: CELL, height: 24)
            }
        }
        .padding(.horizontal, PAD)
    }

    private func weekdayColor(_ col: Int) -> Color {
        if col == 0 { return Color(nsColor: .systemRed) }
        if col == 6 { return Color(nsColor: .systemBlue) }
        return .secondary
    }

    // MARK: - 日付グリッド

    private var calendarGrid: some View {
        let weeks = self.weeks
        return VStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        dayCell(day: weeks[row][col], col: col)
                    }
                }
            }
        }
        .padding(.horizontal, PAD)
        .padding(.bottom, 4)
    }

    /// 日曜始まりの月間カレンダー（6週分・空きセルは0）
    private var weeks: [[Int]] {
        let first = gregorian.date(
            from: DateComponents(year: year, month: month, day: 1))!
        let firstWeekday = gregorian.component(.weekday, from: first)  // 1=日
        let numDays = gregorian.range(of: .day, in: .month, for: first)!.count
        var days = Array(repeating: 0, count: firstWeekday - 1) + Array(1...numDays)
        while days.count < 42 { days.append(0) }
        return stride(from: 0, to: 42, by: 7).map { Array(days[$0..<$0 + 7]) }
    }

    @ViewBuilder
    private func dayCell(day: Int, col: Int) -> some View {
        if day == 0 {
            Color.clear.frame(width: CELL, height: CELL)
        } else {
            let holiday = JapaneseHoliday.name(year: year, month: month, day: day)
            let isToday = isTodayCell(day)
            let cell = ZStack {
                if isToday {
                    Circle()
                        .fill(Color(nsColor: .systemBlue))
                        .padding(3)
                }
                Text("\(day)")
                    .font(.system(size: 13, weight: isToday ? .bold : .regular))
                    .foregroundColor(dayColor(col: col,
                                              isToday: isToday,
                                              isHoliday: holiday != nil))
                if holiday != nil && !isToday {
                    VStack {
                        Spacer()
                        Circle()
                            .fill(Color(nsColor: .systemRed))
                            .frame(width: 3, height: 3)
                            .padding(.bottom, 4)
                    }
                }
            }
            .frame(width: CELL, height: CELL)

            if let holiday {
                cell.help(holiday)
            } else {
                cell
            }
        }
    }

    private func isTodayCell(_ day: Int) -> Bool {
        let t = gregorian.dateComponents([.year, .month, .day], from: today)
        return t.year == year && t.month == month && t.day == day
    }

    private func dayColor(col: Int, isToday: Bool, isHoliday: Bool) -> Color {
        if isToday { return .white }
        if col == 0 || isHoliday { return Color(nsColor: .systemRed) }
        if col == 6 { return Color(nsColor: .systemBlue) }
        return .primary
    }

    // MARK: - フッター（今日の日付 + 今日ボタン + 設定メニュー）

    private var footer: some View {
        HStack(spacing: 8) {
            Text(todayLabel)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
            Spacer()
            Button("今日") { goToday() }
                .font(.system(size: 11))
                .controlSize(.small)
            Menu {
                Toggle("ログイン時に自動起動", isOn: $launchAtLogin)
                Divider()
                Button("Quick Calendarを終了") {
                    NSApp.terminate(nil)
                }
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, PAD)
        .frame(height: 34)
        .onChange(of: launchAtLogin) { newValue in
            do {
                try LoginItem.setEnabled(newValue)
            } catch {
                // 登録に失敗したら表示を実状態に戻す
                launchAtLogin = LoginItem.isEnabled
            }
        }
    }

    private var todayLabel: String {
        let t = gregorian.dateComponents([.year, .month, .day, .weekday], from: today)
        var text = "今日  \(String(t.year!))年\(t.month!)月\(t.day!)日"
            + "（\(WEEKDAYS_JP[t.weekday! - 1])）"
        if let holiday = JapaneseHoliday.name(
            year: t.year!, month: t.month!, day: t.day!) {
            text += "  \(holiday)"
        }
        return text
    }

    // MARK: - 操作

    private func moveMonth(_ delta: Int) {
        var m = month + delta
        if m < 1 { m = 12; year -= 1 }
        if m > 12 { m = 1; year += 1 }
        month = m
    }

    private func goToday() {
        let now = gregorian.dateComponents([.year, .month], from: Date())
        year = now.year!
        month = now.month!
        today = Date()
    }
}
