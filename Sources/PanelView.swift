import SwiftUI

let amber = Color(red: 0.976, green: 0.616, blue: 0.200)   // 主色杏黄 #F99D33

// 进账暗红：浅色用暗红，深色自动换亮橙红保证可读
let earningRed = Color(nsColor: NSColor(name: "earningRed") { appearance in
    if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
        return NSColor(red: 0.985, green: 0.43, blue: 0.35, alpha: 1)
    }
    return NSColor(red: 0.72, green: 0.15, blue: 0.12, alpha: 1)
})

struct PanelView: View {
    @ObservedObject private var ticker = sharedTicker

    var body: some View {
        let cfg = loadConfig()
        let snap = snapshot(now: ticker.frozenNow, isPaused: ticker.paused, cfg: cfg)
        let sight = goodsSight(earned: snap.earned, perSecond: cfg.perSecond, goods: loadGoods())

        VStack(alignment: .leading, spacing: 14) {
            header
            Text(clockText(ticker.now))
                .font(.system(size: 13).monospacedDigit())
                .foregroundStyle(.secondary)

            stateHeadline(snap, cfg: cfg)

            VStack(alignment: .leading, spacing: 5) {
                Text("今日已赚")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(money(snap.earned, digits: 4))
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(earningRed)
                Text("当前赚钱速度 \(money(cfg.perSecond, digits: 4)) / 秒")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                if ticker.paused {
                    Label("已暂停，时间冻结在 \(clockText(ticker.frozenNow))",
                          systemImage: "pause.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(amber)
                }
            }

            encourageLines(snap, sight: sight)

            if snap.state == .working || snap.state == .lunch {
                Button {
                    ticker.togglePause()
                } label: {
                    Text(ticker.paused ? "继续计时" : "暂停计时")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(RoundedRectangle(cornerRadius: 10).fill(amber))
                .foregroundStyle(.white)
            }

            progressBlock(snap)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text("本月累计")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(money(snap.monthly))
                        .font(.system(size: 18, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(earningRed)
                }
                Text("已过的日子按满勤补算。本月只计已赚，不含亏损。")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Text("时薪 \(money(cfg.hourly))")
                Spacer()
                Text("今日满勤可得 \(money(cfg.fullDayPay))")
            }
            .font(.footnote.monospacedDigit())
            .foregroundStyle(.secondary)

            Divider()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("退出上班鼓励器", systemImage: "xmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
    }

    // MARK: - 区块

    private var header: some View {
        HStack {
            Image(systemName: "yensign.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(amber)
            Text("上班鼓励器")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button {
                openSettingsWindow()
            } label: {
                Label("设置", systemImage: "gearshape")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func stateHeadline(_ snap: Snapshot, cfg: WorkConfig) -> some View {
        switch snap.state {
        case .working:
            VStack(alignment: .leading, spacing: 4) {
                Text("上班中")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(red: 0.18, green: 0.44, blue: 0.93))
                Text("距离下班还有 \(durText(snap.toOff ?? 0))")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        case .lunch:
            VStack(alignment: .leading, spacing: 4) {
                Text("午休中")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(amber)
                Text("吃饭别想 KPI，金额暂停跳动，下午接着涨")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        case .afterWork:
            VStack(alignment: .leading, spacing: 4) {
                Text("已下班")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.secondary)
                Text("今日满勤 \(money(cfg.fullDayPay)) 已入账，去玩吧")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        case .beforeWork:
            VStack(alignment: .leading, spacing: 4) {
                Text("待上班")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.secondary)
                Text("距离上班还有 \(durText(snap.toStart ?? 0))，钱已经在路上")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        case .offDay:
            VStack(alignment: .leading, spacing: 4) {
                Text("休假日")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(red: 0.13, green: 0.60, blue: 0.56))
                Text("今天不打卡，好好休息就是给自己充电")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func encourageLines(_ snap: Snapshot, sight: GoodsSight) -> some View {
        if snap.state != .offDay && snap.state != .beforeWork {
            VStack(alignment: .leading, spacing: 5) {
                if let owned = sight.owned {
                    Label {
                        Text("已经赚回「\(owned.name)」")
                    } icon: {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(amber)
                    }
                    .font(.footnote)
                    .foregroundStyle(.primary)
                }
                if let next = sight.next, let eta = sight.etaSeconds {
                    Text("再过 \(durText(eta, withSeconds: false))，「\(next.name)」就赚回来了")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if sight.next == nil, sight.owned != nil {
                    Text("清单上的东西今天全都赚回来了，还多 \(money(sight.surplus))，收工底气十足")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func progressBlock(_ snap: Snapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("今日工时进度 \(Int((snap.progress * 100).rounded()))%")
                Spacer()
                Text(String(format: "已工作 %.2f / %.2f 小时", snap.workedHours, snap.totalHours))
            }
            .font(.footnote.monospacedDigit())
            .foregroundStyle(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.22))
                    Capsule()
                        .fill(amber)
                        .frame(width: max(6, geo.size.width * snap.progress))
                }
            }
            .frame(height: 7)
        }
    }
}
