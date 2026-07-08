import Foundation

/// 日本の祝日判定（2000〜2099年対応・オフライン計算）
/// jpholiday と同じ命名規則（振替は「〈祝日名〉 振替休日」）で名称を返す。
enum JapaneseHoliday {
    private static var cache: [Int: [Int: String]] = [:]

    /// 祝日名を返す。祝日でなければ nil。
    static func name(year: Int, month: Int, day: Int) -> String? {
        guard (2000...2099).contains(year) else { return nil }
        if cache[year] == nil {
            cache[year] = computeHolidays(year: year)
        }
        return cache[year]?[month * 100 + day]
    }

    // MARK: - 計算

    private static func computeHolidays(year: Int) -> [Int: String] {
        var base: [Int: String] = [:]

        func add(_ month: Int, _ day: Int, _ name: String) {
            base[month * 100 + day] = name
        }

        add(1, 1, "元日")
        add(1, nthWeekday(2, weekday: 2, month: 1, year: year), "成人の日")
        add(2, 11, "建国記念の日")
        add(3, vernalEquinoxDay(year), "春分の日")
        add(4, 29, year >= 2007 ? "昭和の日" : "みどりの日")
        add(5, 3, "憲法記念日")
        if year >= 2007 { add(5, 4, "みどりの日") }
        add(5, 5, "こどもの日")
        add(9, autumnalEquinoxDay(year), "秋分の日")
        add(11, 3, "文化の日")
        add(11, 23, "勤労感謝の日")

        // 天皇誕生日（2019年は代替わりでなし）
        if year <= 2018 {
            add(12, 23, "天皇誕生日")
        } else if year >= 2020 {
            add(2, 23, "天皇誕生日")
        }

        // 海の日
        switch year {
        case 2020: add(7, 23, "海の日")           // 東京五輪特例
        case 2021: add(7, 22, "海の日")
        case ...2002: add(7, 20, "海の日")
        default: add(7, nthWeekday(3, weekday: 2, month: 7, year: year), "海の日")
        }

        // 山の日（2016年施行）
        switch year {
        case 2020: add(8, 10, "山の日")
        case 2021: add(8, 8, "山の日")
        case 2016...: add(8, 11, "山の日")
        default: break
        }

        // 敬老の日
        if year <= 2002 {
            add(9, 15, "敬老の日")
        } else {
            add(9, nthWeekday(3, weekday: 2, month: 9, year: year), "敬老の日")
        }

        // 体育の日 / スポーツの日
        switch year {
        case 2020: add(7, 24, "スポーツの日")      // 東京五輪特例
        case 2021: add(7, 23, "スポーツの日")
        default:
            let d = nthWeekday(2, weekday: 2, month: 10, year: year)
            add(10, d, year >= 2020 ? "スポーツの日" : "体育の日")
        }

        // 2019年 皇位継承の特例
        if year == 2019 {
            add(5, 1, "天皇の即位の日")
            add(10, 22, "即位礼正殿の儀")
        }

        var result = base

        // 振替休日: 日曜に当たる祝日は、その後の最初の「祝日でない日」が休日になる
        for (key, name) in base {
            let (m, d) = (key / 100, key % 100)
            guard weekday(year: year, month: m, day: d) == 1 else { continue }
            var next = dayAfter(year: year, month: m, day: d)
            while base[next.month * 100 + next.day] != nil {
                next = dayAfter(year: year, month: next.month, day: next.day)
            }
            result[next.month * 100 + next.day] = "\(name) 振替休日"
        }

        // 国民の休日: 前後を祝日に挟まれた平日（日曜・既存の休日を除く）
        for (key, _) in base {
            let (m, d) = (key / 100, key % 100)
            let mid = dayAfter(year: year, month: m, day: d)
            let midKey = mid.month * 100 + mid.day
            let after = dayAfter(year: year, month: mid.month, day: mid.day)
            guard result[midKey] == nil,
                  base[after.month * 100 + after.day] != nil,
                  weekday(year: year, month: mid.month, day: mid.day) != 1
            else { continue }
            result[midKey] = "国民の休日"
        }

        return result
    }

    // MARK: - 暦ユーティリティ

    private static var gregorian: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        return cal
    }()

    /// 第n○曜日の日付（weekday: 1=日 2=月 ... 7=土）
    private static func nthWeekday(_ n: Int, weekday: Int, month: Int, year: Int) -> Int {
        let comps = DateComponents(year: year, month: month,
                                   weekday: weekday, weekdayOrdinal: n)
        let date = gregorian.date(from: comps)!
        return gregorian.component(.day, from: date)
    }

    /// 曜日（1=日曜 ... 7=土曜）
    private static func weekday(year: Int, month: Int, day: Int) -> Int {
        let date = gregorian.date(from: DateComponents(year: year, month: month, day: day))!
        return gregorian.component(.weekday, from: date)
    }

    private static func dayAfter(year: Int, month: Int, day: Int) -> (month: Int, day: Int) {
        let date = gregorian.date(from: DateComponents(year: year, month: month, day: day))!
        let next = gregorian.date(byAdding: .day, value: 1, to: date)!
        let comps = gregorian.dateComponents([.month, .day], from: next)
        return (comps.month!, comps.day!)
    }

    /// 春分の日（2000〜2099年で有効な近似式）
    private static func vernalEquinoxDay(_ year: Int) -> Int {
        Int(20.8431 + 0.242194 * Double(year - 1980)) - (year - 1980) / 4
    }

    /// 秋分の日（2000〜2099年で有効な近似式）
    private static func autumnalEquinoxDay(_ year: Int) -> Int {
        Int(23.2488 + 0.242194 * Double(year - 1980)) - (year - 1980) / 4
    }
}
