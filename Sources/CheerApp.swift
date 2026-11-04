import SwiftUI
import ServiceManagement

// MARK: - 全局秒针：驱动菜单栏与面板每秒刷新

final class Ticker: ObservableObject {
    @Published var now = Date()
    @Published var pauseStart: Date? = nil
    @Published var pausedTotal: TimeInterval = 0

    private let cal = Calendar.current

    init() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    /// 暂停时冻结的有效时刻
    var frozenNow: Date { pauseStart ?? now }
    var paused: Bool { pauseStart != nil }

    func togglePause() {
        if let p = pauseStart {
            pausedTotal += Date().timeIntervalSince(p)
            pauseStart = nil
        } else {
            pauseStart = Date()
        }
    }

    private func tick() {
        let t = Date()
        // 跨天：暂停状态作废
        if !cal.isDate(frozenNow, inSameDayAs: t) {
            pauseStart = nil
            pausedTotal = 0
        }
        now = t
    }
}

let sharedTicker = Ticker()

// MARK: - 设置窗口
// SwiftUI openSettings() 从菜单栏弹层调用经常不生效，直接用 AppKit 开窗

private var settingsWindow: NSWindow? = nil

func openSettingsWindow() {
    if let existing = settingsWindow {
        existing.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }
    let win = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 460, height: 560),
        styleMask: [.titled, .closable],
        backing: .buffered, defer: false
    )
    win.title = "设置"
    win.contentView = NSHostingView(rootView: SettingsView())
    win.isReleasedWhenClosed = false
    win.center()
    win.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    settingsWindow = win
}

// MARK: - 调试窗口：CHEER_DEBUG_WINDOW=1 时开普通窗口承载面板，便于截图验收

final class DebugWindowDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let env = ProcessInfo.processInfo.environment
        if env["CHEER_DEBUG_WINDOW"] == "1" {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 700),
                styleMask: [.titled, .closable],
                backing: .buffered, defer: false
            )
            win.title = "上班鼓励器"
            win.contentView = NSHostingView(rootView: PanelView().frame(width: 360))
            win.center()
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        if env["CHEER_DEBUG_SETTINGS"] == "1" {
            openSettingsWindow()
        }
    }
}

@main
struct CheerApp: App {
    @ObservedObject private var ticker = sharedTicker
    @NSApplicationDelegateAdaptor(DebugWindowDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            PanelView()
                .frame(width: 360)
        } label: {
            Text(menuTitle)
        }
        .menuBarExtraStyle(.window)
    }

    private var menuTitle: String {
        _ = ticker.now // 依赖秒针触发重算
        let cfg = loadConfig()
        let snap = snapshot(now: ticker.frozenNow, isPaused: ticker.paused, cfg: cfg)
        if snap.state == .offDay { return "休假" }
        return money(snap.earned)
    }
}
