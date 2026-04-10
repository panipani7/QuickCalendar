#!/usr/bin/env python3
"""macOS メニューバー カレンダーアプリ（ネイティブUI版）"""
import os
import objc
from AppKit import *
from Foundation import *
import calendar
import jpholiday
from datetime import date, datetime

calendar.setfirstweekday(6)  # 日曜始まり

# レイアウト定数
CELL     = 36   # 日付セルのサイズ
PAD      = 14   # 左右パディング
HDR      = 48   # ヘッダー（年月 + ナビ）高さ
WDH      = 28   # 曜日ラベル行の高さ
ROWS     = 6    # 最大6週分
FOOTER_H = 38   # フッター（今日の日付表示）高さ
VIEW_W   = 7 * CELL + PAD * 2
VIEW_H   = HDR + WDH + ROWS * CELL + FOOTER_H

WEEKDAYS_JP = ["月", "火", "水", "木", "金", "土", "日"]


class CalendarView(NSView):
    """カレンダーグリッドを描画するカスタムビュー"""

    def initWithFrame_(self, frame):
        self = objc.super(CalendarView, self).initWithFrame_(frame)
        if self is None:
            return None
        today = date.today()
        self._year      = today.year
        self._month     = today.month
        self._today     = today
        self._tip_tags  = []  # アクティブなツールチップタグ
        self._build_controls()
        return self

    @objc.python_method
    def _build_controls(self):
        # ‹ 前月ボタン
        self._btn_prev = NSButton.alloc().initWithFrame_(
            NSMakeRect(PAD - 4, VIEW_H - HDR + 9, 32, 32))
        self._btn_prev.setTitle_("‹")
        self._btn_prev.setBordered_(False)
        self._btn_prev.setFont_(NSFont.systemFontOfSize_(20))
        self._btn_prev.setTarget_(self)
        self._btn_prev.setAction_("prevMonth:")
        self.addSubview_(self._btn_prev)

        # 年月ラベル（中央）
        self._lbl_month = NSTextField.labelWithString_("")
        self._lbl_month.setFrame_(
            NSMakeRect(PAD + 28, VIEW_H - HDR + 13,
                       VIEW_W - PAD * 2 - 56, 24))
        self._lbl_month.setFont_(NSFont.boldSystemFontOfSize_(14))
        self._lbl_month.setAlignment_(NSTextAlignmentCenter)
        self.addSubview_(self._lbl_month)

        # › 翌月ボタン
        self._btn_next = NSButton.alloc().initWithFrame_(
            NSMakeRect(VIEW_W - PAD - 28, VIEW_H - HDR + 9, 32, 32))
        self._btn_next.setTitle_("›")
        self._btn_next.setBordered_(False)
        self._btn_next.setFont_(NSFont.systemFontOfSize_(20))
        self._btn_next.setTarget_(self)
        self._btn_next.setAction_("nextMonth:")
        self.addSubview_(self._btn_next)

        # フッター: 今日の日付ラベル
        self._lbl_today = NSTextField.labelWithString_("")
        self._lbl_today.setFrame_(NSMakeRect(PAD, 10, VIEW_W - PAD * 2 - 52, 20))
        self._lbl_today.setFont_(NSFont.systemFontOfSize_(11))
        self._lbl_today.setTextColor_(NSColor.secondaryLabelColor())
        self.addSubview_(self._lbl_today)

        # フッター: 「今日」ボタン（当月に戻る）
        self._btn_today = NSButton.alloc().initWithFrame_(
            NSMakeRect(VIEW_W - PAD - 42, 8, 42, 22))
        self._btn_today.setTitle_("今日")
        self._btn_today.setBezelStyle_(NSBezelStyleInline)
        self._btn_today.setFont_(NSFont.systemFontOfSize_(11))
        self._btn_today.setTarget_(self)
        self._btn_today.setAction_("goToday:")
        self.addSubview_(self._btn_today)

        self._refresh_month_label()
        self._refresh_today_label()
        self._setup_tooltips()

    @objc.python_method
    def _refresh_month_label(self):
        months = ["1月","2月","3月","4月","5月","6月",
                  "7月","8月","9月","10月","11月","12月"]
        self._lbl_month.setStringValue_(f"{self._year}年 {months[self._month - 1]}")

    @objc.python_method
    def _refresh_today_label(self):
        t = self._today
        wd = WEEKDAYS_JP[t.weekday()]
        text = f"今日  {t.year}年{t.month}月{t.day}日（{wd}）"
        holiday = jpholiday.is_holiday_name(t)
        if holiday:
            text += f"  {holiday}"
        self._lbl_today.setStringValue_(text)

    def prevMonth_(self, sender):
        if self._month == 1:
            self._month, self._year = 12, self._year - 1
        else:
            self._month -= 1
        self._refresh_month_label()
        self._setup_tooltips()
        self.setNeedsDisplay_(True)

    def nextMonth_(self, sender):
        if self._month == 12:
            self._month, self._year = 1, self._year + 1
        else:
            self._month += 1
        self._refresh_month_label()
        self._setup_tooltips()
        self.setNeedsDisplay_(True)

    def goToday_(self, sender):
        today = date.today()
        self._year  = today.year
        self._month = today.month
        self._refresh_month_label()
        self._setup_tooltips()
        self.setNeedsDisplay_(True)

    def refreshToday_(self, _):
        self._today = date.today()
        self._refresh_month_label()
        self._refresh_today_label()
        self._setup_tooltips()
        self.setNeedsDisplay_(True)

    @objc.python_method
    def _setup_tooltips(self):
        """祝日セルにツールチップ矩形を登録する"""
        # 古いツールチップを削除
        for tag in self._tip_tags:
            self.removeToolTip_(tag)
        self._tip_tags = []

        holidays = self._holidays_in_month(self._year, self._month)
        weeks    = calendar.monthcalendar(self._year, self._month)

        for row, week in enumerate(weeks):
            for col, d in enumerate(week):
                if d == 0 or d not in holidays:
                    continue
                x0  = PAD + col * CELL
                y0  = VIEW_H - HDR - WDH - (row + 1) * CELL
                tag = self.addToolTipRect_owner_userData_(
                    NSMakeRect(x0, y0, CELL, CELL), self, None)
                self._tip_tags.append(tag)

    def view_stringForToolTip_point_userData_(self, view, tag, point, userData):
        """ツールチップ文字列を返す（マウス位置から祝日名を判定）"""
        col = int((point.x - PAD) / CELL)
        row = int((VIEW_H - HDR - WDH - point.y) / CELL)

        weeks = calendar.monthcalendar(self._year, self._month)
        if 0 <= row < len(weeks) and 0 <= col < 7:
            d = weeks[row][col]
            if d != 0:
                name = jpholiday.is_holiday_name(date(self._year, self._month, d))
                if name:
                    return name
        return ""

    def drawRect_(self, rect):
        NSColor.windowBackgroundColor().setFill()
        NSBezierPath.fillRect_(self.bounds())

        NSColor.separatorColor().setStroke()

        # ヘッダー下の区切り線
        self._draw_separator(VIEW_H - HDR)
        # フッター上の区切り線
        self._draw_separator(FOOTER_H)

        self._draw_weekday_row()
        self._draw_day_cells()

    @objc.python_method
    def _draw_separator(self, y):
        line = NSBezierPath.bezierPath()
        line.moveToPoint_(NSMakePoint(PAD, y))
        line.lineToPoint_(NSMakePoint(VIEW_W - PAD, y))
        line.setLineWidth_(0.5)
        line.stroke()

    @objc.python_method
    def _draw_weekday_row(self):
        labels = ["日", "月", "火", "水", "木", "金", "土"]
        colors = (
            [NSColor.systemRedColor()] +
            [NSColor.secondaryLabelColor()] * 5 +
            [NSColor.systemBlueColor()]
        )
        y = VIEW_H - HDR - WDH
        font = NSFont.boldSystemFontOfSize_(10)

        for i, (lbl, c) in enumerate(zip(labels, colors)):
            x = PAD + i * CELL
            attrs = {
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: c,
            }
            s = NSAttributedString.alloc().initWithString_attributes_(lbl, attrs)
            sw = s.size().width
            s.drawAtPoint_(NSMakePoint(x + (CELL - sw) / 2, y + 6))

    @objc.python_method
    def _holidays_in_month(self, year, month):
        result = {}
        for week in calendar.monthcalendar(year, month):
            for d in week:
                if d == 0:
                    continue
                name = jpholiday.is_holiday_name(date(year, month, d))
                if name:
                    result[d] = name
        return result

    @objc.python_method
    def _draw_day_cells(self):
        weeks    = calendar.monthcalendar(self._year, self._month)
        today    = self._today
        holidays = self._holidays_in_month(self._year, self._month)

        for row, week in enumerate(weeks):
            y0 = VIEW_H - HDR - WDH - (row + 1) * CELL

            for col, d in enumerate(week):
                if d == 0:
                    continue

                x0 = PAD + col * CELL
                is_today   = (d == today.day and
                              self._month == today.month and
                              self._year  == today.year)
                is_sun     = (col == 0)
                is_sat     = (col == 6)
                is_holiday = d in holidays

                if is_today:
                    margin = 3
                    circle = NSMakeRect(x0 + margin, y0 + margin,
                                        CELL - margin * 2, CELL - margin * 2)
                    NSColor.systemBlueColor().setFill()
                    NSBezierPath.bezierPathWithOvalInRect_(circle).fill()
                    text_color = NSColor.whiteColor()
                    font = NSFont.boldSystemFontOfSize_(13)
                else:
                    if is_sun or is_holiday:
                        text_color = NSColor.systemRedColor()
                    elif is_sat:
                        text_color = NSColor.systemBlueColor()
                    else:
                        text_color = NSColor.labelColor()
                    font = NSFont.systemFontOfSize_(13)

                attrs = {
                    NSFontAttributeName: font,
                    NSForegroundColorAttributeName: text_color,
                }
                s = NSAttributedString.alloc().initWithString_attributes_(str(d), attrs)
                sw, sh = s.size().width, s.size().height
                s.drawAtPoint_(NSMakePoint(
                    x0 + (CELL - sw) / 2,
                    y0 + (CELL - sh) / 2))

                # 祝日ドット
                if is_holiday and not is_today:
                    dot = 3
                    NSColor.systemRedColor().setFill()
                    NSBezierPath.bezierPathWithOvalInRect_(
                        NSMakeRect(x0 + (CELL - dot) / 2, y0 + 4, dot, dot)
                    ).fill()


class AppDelegate(NSObject):
    def applicationDidFinishLaunching_(self, notification):
        self._setup_status_item()
        self._setup_popover()
        self._start_timer()

    @objc.python_method
    def _setup_status_item(self):
        bar = NSStatusBar.systemStatusBar()
        self._item = bar.statusItemWithLength_(NSVariableStatusItemLength)
        self._update_icon()

        btn = self._item.button()
        btn.setTarget_(self)
        btn.setAction_("togglePopover:")
        btn.sendActionOn_(NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp)

        # 右クリックメニュー（終了用）
        menu = NSMenu.alloc().init()
        quit_item = NSMenuItem.alloc().initWithTitle_action_keyEquivalent_(
            "Quick Calendarを終了", "quitApp:", "")
        quit_item.setTarget_(self)
        menu.addItem_(quit_item)
        self._right_click_menu = menu

    @objc.python_method
    def _update_icon(self):
        btn = self._item.button()
        base = os.path.dirname(os.path.abspath(__file__))
        img = NSImage.alloc().initWithSize_(NSMakeSize(22, 22))
        for filename in ["icon.png", "icon@2x.png"]:
            rep = NSBitmapImageRep.imageRepWithContentsOfFile_(
                os.path.join(base, filename))
            if rep:
                img.addRepresentation_(rep)
        img.setTemplate_(True)
        btn.setImage_(img)
        btn.setTitle_("")
        btn.setImagePosition_(NSImageOnly)

    @objc.python_method
    def _setup_popover(self):
        frame = NSMakeRect(0, 0, VIEW_W, VIEW_H)
        self._cal = CalendarView.alloc().initWithFrame_(frame)

        vc = NSViewController.alloc().init()
        vc.setView_(self._cal)

        self._popover = NSPopover.alloc().init()
        self._popover.setContentSize_(NSMakeSize(VIEW_W, VIEW_H))
        self._popover.setContentViewController_(vc)
        self._popover.setBehavior_(NSPopoverBehaviorTransient)

    def togglePopover_(self, sender):
        event = NSApp.currentEvent()
        if event and event.type() == NSEventTypeRightMouseUp:
            self._item.setMenu_(self._right_click_menu)
            self._item.button().performClick_(None)
            self._item.setMenu_(None)
            return
        if self._popover.isShown():
            self._popover.close()
        else:
            btn = self._item.button()
            self._popover.showRelativeToRect_ofView_preferredEdge_(
                btn.bounds(), btn, NSMinYEdge)

    def quitApp_(self, sender):
        NSApplication.sharedApplication().terminate_(None)

    @objc.python_method
    def _start_timer(self):
        NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(
            60.0, self, "timerTick:", None, True)

    def timerTick_(self, timer):
        self._cal.refreshToday_(None)


def main():
    app = NSApplication.sharedApplication()
    app.setActivationPolicy_(NSApplicationActivationPolicyAccessory)
    delegate = AppDelegate.alloc().init()
    app.setDelegate_(delegate)
    app.run()


if __name__ == "__main__":
    main()
