import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage(Keys.salary) private var monthlySalary: Double = 12000
    @AppStorage(Keys.payDays) private var payDays: Double = 21.75
    @AppStorage(Keys.start) private var startTime = "09:00"
    @AppStorage(Keys.end) private var endTime = "18:00"
    @AppStorage(Keys.lunchOn) private var lunchOn = true
    @AppStorage(Keys.lunchStart) private var lunchStart = "12:00"
    @AppStorage(Keys.lunchEnd) private var lunchEnd = "13:00"
    @AppStorage(Keys.anchorName) private var anchorName = defaultAnchor.name
    @AppStorage(Keys.anchorUnit) private var anchorUnit = defaultAnchor.unit
    @AppStorage(Keys.anchorPrice) private var anchorPrice: Double = defaultAnchor.price

    @State private var cfg = loadConfig()

    var body: some View {
        Form {
            Section("薪水（按到手月薪算更真实）") {
                TextField("月薪", value: $monthlySalary, format: dblFmt)
                TextField("每月计薪天数", value: $payDays, format: dblFmt)
                HStack {
                    Text("折算时薪")
                    Spacer()
                    Text(money(cfg.hourly))
                    Text("· 满勤日薪 \(money(cfg.fullDayPay))")
                        .foregroundStyle(.secondary)
                }
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            Section("锚定物品（工资按它来算）") {
                HStack {
                    TextField("名称", text: $anchorName)
                        .textFieldStyle(.plain)
                    TextField("单位", text: $anchorUnit)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .frame(width: 70)
                    TextField("", value: $anchorPrice, format: dblFmt)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                    Text("元/" + (anchorUnit.isEmpty ? "个" : anchorUnit))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("主界面会显示「今天赚了多少\(anchorUnit.isEmpty ? "个" : anchorUnit)\(anchorName)」。比如一杯奶茶 16 元，下班时数字就是 34.5 杯奶茶。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("恢复默认（\(defaultAnchor.name) · \(defaultAnchor.price) 元/\(defaultAnchor.unit)）") {
                    anchorName = defaultAnchor.name
                    anchorUnit = defaultAnchor.unit
                    anchorPrice = defaultAnchor.price
                }
                .buttonStyle(.plain)
                .font(.callout)
            }

            Section("作息") {
                DatePicker("上班时间", selection: binding($startTime, fallback: "09:00"),
                           displayedComponents: .hourAndMinute)
                DatePicker("下班时间", selection: binding($endTime, fallback: "18:00"),
                           displayedComponents: .hourAndMinute)
                Toggle("午休不计薪", isOn: $lunchOn)
                if lunchOn {
                    DatePicker("午休开始", selection: binding($lunchStart, fallback: "12:00"),
                               displayedComponents: .hourAndMinute)
                    DatePicker("午休结束", selection: binding($lunchEnd, fallback: "13:00"),
                               displayedComponents: .hourAndMinute)
                }
            }

            Section("其他") {
                Toggle("开机自动启动", isOn: launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 560)
        .onAppear { cfg = loadConfig() }
        .onChange(of: monthlySalary) { _, _ in cfg = loadConfig() }
        .onChange(of: payDays) { _, _ in cfg = loadConfig() }
        .onChange(of: startTime) { _, _ in cfg = loadConfig() }
        .onChange(of: endTime) { _, _ in cfg = loadConfig() }
        .onChange(of: lunchOn) { _, _ in cfg = loadConfig() }
        .onChange(of: lunchStart) { _, _ in cfg = loadConfig() }
        .onChange(of: lunchEnd) { _, _ in cfg = loadConfig() }
    }

    // "HH:mm" 字符串 <-> DatePicker 日期
    private func binding(_ storage: Binding<String>, fallback: String) -> Binding<Date> {
        Binding(
            get: { parseStoreTime(storage.wrappedValue) ?? parseStoreTime(fallback) ?? Date() },
            set: { storage.wrappedValue = storeTime($0) }
        )
    }

    private var launchAtLogin: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { on in
                do {
                    if on { try SMAppService.mainApp.register() }
                    else { try SMAppService.mainApp.unregister() }
                } catch {
                    NSLog("开机启动设置失败: \(error.localizedDescription)")
                }
            }
        )
    }
}

private let dblFmt: FloatingPointFormatStyle<Double> = .number

private let storeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f
}()

func parseStoreTime(_ s: String) -> Date? {
    storeFormatter.date(from: s)
}

func storeTime(_ d: Date) -> String {
    storeFormatter.string(from: d)
}
