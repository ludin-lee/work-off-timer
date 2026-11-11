import Cocoa

let workSeconds: TimeInterval = 9 * 3600  // 8시간 근무 + 점심 1시간
let defaults = UserDefaults.standard

// 오늘 날짜의 저장값만 유효 (어제 값은 무시)
func todayValue(_ key: String) -> Date? {
    guard let d = defaults.object(forKey: key) as? Date, Calendar.current.isDateInToday(d) else { return nil }
    return d
}

// 오늘 출근 기록이 없으면 앱이 켜진 시각을 출근으로 저장
func startTime() -> Date {
    if let d = todayValue("start") { return d }
    defaults.set(Date(), forKey: "start")
    return Date()
}

// 직접 정한 퇴근 시각(반차 등)이 있으면 그것, 없으면 출근 + 9시간
func endTime() -> Date { todayValue("end") ?? startTime().addingTimeInterval(workSeconds) }

func hms(_ s: TimeInterval) -> String {
    let t = Int(s)
    return String(format: "%d:%02d:%02d", t / 3600, t / 60 % 60, t % 60)
}

// 시:분 입력 창. 취소하면 nil
func askTime(_ title: String, _ initial: Date) -> Date? {
    let picker = NSDatePicker(frame: NSRect(x: 0, y: 0, width: 100, height: 24))
    picker.datePickerElements = .hourMinute
    picker.datePickerStyle = .textFieldAndStepper
    picker.dateValue = initial  // initial이 오늘이라 날짜는 오늘로 유지됨
    let alert = NSAlert()
    alert.messageText = title
    alert.accessoryView = picker
    alert.addButton(withTitle: "확인")
    alert.addButton(withTitle: "취소")
    NSApp.activate(ignoringOtherApps: true)
    return alert.runModal() == .alertFirstButtonReturn ? picker.dateValue : nil
}

class App: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let info = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    let t: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm"; return f }()

    func applicationDidFinishLaunching(_ n: Notification) {
        let menu = NSMenu()
        menu.addItem(info)
        menu.addItem(.separator())
        for (title, sel) in [("출근 시간 설정…", #selector(setStart)),
                             ("퇴근 시간 직접 설정… (반차/반반차)", #selector(setEnd)),
                             ("퇴근 시간 기본값(+9시간)으로", #selector(clearEnd))] {
            let mi = NSMenuItem(title: title, action: sel, keyEquivalent: "")
            mi.target = self
            menu.addItem(mi)
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "종료", action: #selector(NSApp.terminate), keyEquivalent: "q"))
        item.menu = menu
        tick()
        // .common 모드: 메뉴가 열려 있는 동안에도 계속 갱신
        RunLoop.main.add(Timer(timeInterval: 1, repeats: true) { _ in self.tick() }, forMode: .common)
    }

    @objc func setStart() {
        if let d = askTime("오늘 출근 시간", startTime()) { defaults.set(d, forKey: "start"); tick() }
    }
    @objc func setEnd() {
        if let d = askTime("오늘 퇴근 시간", endTime()) { defaults.set(d, forKey: "end"); tick() }
    }
    @objc func clearEnd() { defaults.removeObject(forKey: "end"); tick() }

    func tick() {
        let left = endTime().timeIntervalSinceNow
        let text = left > 0 ? "퇴근까지 \(hms(left))" : "퇴근! +\(hms(-left))"
        // 고정폭 숫자: 매초 글자 폭이 흔들리지 않게
        item.button?.attributedTitle = NSAttributedString(string: text, attributes:
            [.font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)])
        info.title = "출근 \(t.string(from: startTime())) → 퇴근 \(t.string(from: endTime()))"
            + (todayValue("end") != nil ? " (직접 설정)" : "")
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)  // Dock 아이콘 없이 메뉴바에만
app.run()
