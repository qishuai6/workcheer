import Foundation

// MARK: - 锚定物品：工资按它来算，主视觉显示「赚了多少个」

struct Anchor {
    let name: String   // 奶茶
    let unit: String   // 杯
    let price: Double  // 单价 ¥16
}

let defaultAnchor = Anchor(name: "奶茶", unit: "杯", price: 16)

func loadAnchor() -> Anchor {
    let d = UserDefaults.standard
    return Anchor(
        name: d.string(forKey: Keys.anchorName) ?? defaultAnchor.name,
        unit: d.string(forKey: Keys.anchorUnit) ?? defaultAnchor.unit,
        price: d.object(forKey: Keys.anchorPrice) as? Double ?? defaultAnchor.price
    )
}

func saveAnchor(_ a: Anchor) {
    let d = UserDefaults.standard
    d.set(a.name, forKey: Keys.anchorName)
    d.set(a.unit, forKey: Keys.anchorUnit)
    d.set(a.price, forKey: Keys.anchorPrice)
}

extension Anchor {
    /// 金额换算成物品数量
    func count(of money: Double) -> Double { money / max(0.01, price) }
}

// MARK: - 配置

enum Keys {
    static let salary = "monthlySalary"
    static let payDays = "payDaysPerMonth"
    static let start = "workStartTime"
    static let end = "workEndTime"
    static let lunchOn = "lunchDeductOn"
    static let lunchStart = "lunchStartTime"
    static let lunchEnd = "lunchEndTime"
    static let anchorName = "anchorName"
    static let anchorUnit = "anchorUnit"
    static let anchorPrice = "anchorPrice"
}

struct WorkConfig {
    var monthlySalary: Double = 10000
    var payDays: Double = 21.75
    var startSeconds: Double = 9 * 3600
    var endSeconds: Double = 18 * 3600
    var lunchOn: Bool = true
    var lunchStartSeconds: Double = 12 * 3600
    var lunchEndSeconds: Double = 13 * 3600

    var shiftSeconds: Double { max(0, endSeconds - startSeconds) }
    var lunchSeconds: Double { lunchOn ? max(0, lunchEndSeconds - lunchStartSeconds) : 0 }
    // 每日实际计薪时长（午休不计薪时扣除）
    var paidSeconds: Double { max(60, shiftSeconds - lunchSeconds) }
    // 口径自洽：时薪按每日实际计薪时长折算，满勤日薪 = 月薪 / 计薪天数
    var hourly: Double { monthlySalary / (payDays * paidSeconds / 3600) }
    var perSecond: Double { hourly / 3600 }
    var fullDayPay: Double { monthlySalary / payDays }
}

func secondsFrom(_ hhmm: String, fallback: Double) -> Double {
    let parts = hhmm.split(separator: ":")
    guard parts.count == 2,
          let h = Int(parts[0]), let m = Int(parts[1]),
          (0..<24).contains(h), (0..<60).contains(m) else { return fallback }
    return Double(h * 3600 + m * 60)
}

func loadConfig() -> WorkConfig {
    let d = UserDefaults.standard
    var cfg = WorkConfig()
    cfg.monthlySalary = d.object(forKey: Keys.salary) as? Double ?? cfg.monthlySalary
    cfg.payDays = d.object(forKey: Keys.payDays) as? Double ?? cfg.payDays
    let startRaw = d.string(forKey: Keys.start) ?? "09:00"
    let endRaw = d.string(forKey: Keys.end) ?? "18:00"
    let lunchStartRaw = d.string(forKey: Keys.lunchStart) ?? "12:00"
    let lunchEndRaw = d.string(forKey: Keys.lunchEnd) ?? "13:00"
    cfg.startSeconds = secondsFrom(startRaw, fallback: cfg.startSeconds)
    cfg.endSeconds = secondsFrom(endRaw, fallback: cfg.endSeconds)
    cfg.lunchOn = d.object(forKey: Keys.lunchOn) as? Bool ?? cfg.lunchOn
    cfg.lunchStartSeconds = secondsFrom(lunchStartRaw, fallback: cfg.lunchStartSeconds)
    cfg.lunchEndSeconds = secondsFrom(lunchEndRaw, fallback: cfg.lunchEndSeconds)
    return cfg
}

// MARK: - 一天中的状态

enum DayState: Equatable {
    case offDay      // 周末
    case beforeWork  // 还没到上班时间
    case working     // 上班中
    case lunch       // 午休（不计薪）
    case afterWork   // 已下班，满勤入账
}

struct Snapshot {
    var state: DayState
    var earned: Double          // 今日已赚
    var workedHours: Double     // 已计薪小时
    var totalHours: Double      // 每日计薪总小时
    var progress: Double        // 0...1
    var monthly: Double         // 本月累计
    var toOff: TimeInterval?    // 距下班
    var toStart: TimeInterval?  // 距上班
    var isPaused: Bool
}

private func overlap(_ a1: Double, _ a2: Double, _ b1: Double, _ b2: Double) -> Double {
    max(0, min(a2, b2) - max(a1, b1))
}

/// now 传「有效时刻」：暂停中即为暂停冻结的时刻
func snapshot(now: Date, isPaused: Bool, cfg: WorkConfig, cal: Calendar = .current) -> Snapshot {
    let midnight = cal.startOfDay(for: now)
    let sec = now.timeIntervalSince(midnight)
    let weekday = cal.component(.weekday, from: now)
    let isWeekend = weekday == 1 || weekday == 7

    // 到时刻 t 为止的已计薪秒数
    func workedAt(_ t: Double) -> Double {
        let capped = min(max(t, cfg.startSeconds), cfg.endSeconds)
        let raw = capped - cfg.startSeconds
        let lunch = overlap(cfg.startSeconds, capped, cfg.lunchStartSeconds, cfg.lunchEndSeconds)
        return min(max(0, raw - lunch), cfg.paidSeconds)
    }

    let state: DayState
    if isWeekend {
        state = .offDay
    } else if sec < cfg.startSeconds {
        state = .beforeWork
    } else if sec >= cfg.endSeconds {
        state = .afterWork
    } else if cfg.lunchOn && sec >= cfg.lunchStartSeconds && sec < cfg.lunchEndSeconds {
        state = .lunch
    } else {
        state = .working
    }

    let worked: Double
    switch state {
    case .offDay, .beforeWork:
        worked = 0
    case .afterWork:
        worked = cfg.paidSeconds
    case .working, .lunch:
        worked = workedAt(sec)
    }

    let earned = worked * cfg.perSecond

    // 本月累计：已过的日子按满勤补算，今天加实时已赚
    var day = cal.startOfDay(for: now)
    day = cal.date(byAdding: .day, value: -(cal.component(.day, from: now) - 1), to: day) ?? day
    let today = cal.startOfDay(for: now)
    var pastPaidDays = 0.0
    while day < today {
        let wd = cal.component(.weekday, from: day)
        if wd != 1 && wd != 7 { pastPaidDays += 1 }
        day = cal.date(byAdding: .day, value: 1, to: day) ?? day
    }
    let todayWeekday = cal.component(.weekday, from: now)
    let todayIsWeekday = todayWeekday != 1 && todayWeekday != 7
    let monthly = pastPaidDays * cfg.fullDayPay + (todayIsWeekday ? earned : 0)

    return Snapshot(
        state: state,
        earned: earned,
        workedHours: worked / 3600,
        totalHours: cfg.paidSeconds / 3600,
        progress: min(1, worked / cfg.paidSeconds),
        monthly: monthly,
        toOff: (state == .working || state == .lunch) ? max(0, cfg.endSeconds - sec) : nil,
        toStart: state == .beforeWork ? max(0, cfg.startSeconds - sec) : nil,
        isPaused: isPaused
    )
}

// MARK: - 物品数量换算

struct AnchorSight {
    let count: Double            // 当前可买数量（小数）
    let wholeCount: Int          // 已凑满的整数数量
    let etaToNextWhole: TimeInterval  // 距离凑满下一个整数
    let fullDayCount: Double     // 今日满勤可得数量
}

func anchorSight(earned: Double, perSecond: Double, fullDayPay: Double, anchor: Anchor) -> AnchorSight {
    let c = anchor.count(of: earned)
    let whole = Int(c.rounded(.down))
    let nextWholePrice = Double(whole + 1) * anchor.price
    let eta = (nextWholePrice - earned) / max(perSecond, 0.000001)
    return AnchorSight(
        count: c,
        wholeCount: whole,
        etaToNextWhole: eta,
        fullDayCount: anchor.count(of: fullDayPay)
    )
}

// MARK: - 格式化

let cnWeekday = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

func clockText(_ date: Date, cal: Calendar = .current) -> String {
    let c = cal.dateComponents([.year, .month, .day, .weekday, .hour, .minute, .second], from: date)
    let wd = cWeekday(c.weekday ?? 1)
    return String(format: "%04d-%02d-%02d %@ %02d:%02d:%02d",
                  c.year ?? 0, c.month ?? 0, c.day ?? 0, wd,
                  c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
}

private func cWeekday(_ n: Int) -> String { cnWeekday[(n - 1) % 7] }

func durText(_ t: TimeInterval, withSeconds: Bool = true) -> String {
    let s = Int(max(0, t.rounded(.down)))
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    if withSeconds { return "\(h) 小时 \(m) 分 \(sec) 秒" }
    if h > 0 { return "\(h) 小时 \(m) 分" }
    return "\(max(1, m)) 分钟"
}

func money(_ v: Double, digits: Int = 2) -> String {
    String(format: "¥%.\(digits)f", v)
}
