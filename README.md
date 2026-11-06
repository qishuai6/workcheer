# 上班鼓励器 · WorkCheer

把工资实时折算到秒，看着钱一格格涨的桌面小工具。看看自己每一秒值多少钱，今天已经赚回了一杯奶茶还是一顿火锅。

**支持 macOS（菜单栏常驻）和 Windows（桌面窗口），数据全部留在本机，不联网、不上传。**

## 下载安装

到 [Releases](https://github.com/qishuai6/workcheer/releases/latest) 页面下载对应平台的包：

| 平台 | 文件 | 说明 |
|---|---|---|
| macOS | `WorkCheer-macOS-v1.2.zip` | 需 macOS 13.0+（Ventura 及以上，Apple Silicon / Intel 通用）。解压 → 拖进「应用程序」→ 打开 |
| Windows | `WorkCheer-Windows-v1.1-Setup.exe` | 双击安装，装完自动运行，带卸载器 |
| Windows | `WorkCheer-Windows-v1.1-portable.zip` | 免安装版：解压后双击「上班鼓励器.exe」 |

> **macOS 首次打开提示「无法验证开发者」**：右键 App → 「打开」→ 再点「打开」；
> 或终端执行 `xattr -cr /Applications/上班鼓励器.app`。
>
> **Windows 首次打开 SmartScreen 蓝色警告**：点「更多信息」→「仍要运行」。

## 功能

- **锚定物品换算**（v1.1 核心玩法）：自己设一件物品（名称/单位/单价，默认一杯奶茶 16 元），工资按它来算——主界面大数字不再是金额，而是「今天赚了多少杯奶茶」，按秒跳动
- **凑整倒计时**：「再过 12 分钟凑满 2 杯，可以整单拎走」，数字跳到整数那一下最有仪式感
- **下班预期**：「照这个速度，下班时正好 34.5 杯」
- **暂停计时**：时间冻结、数量停涨
- **工时进度条**：已工作 / 总计薪时长
- **本月累计**：已过工作日按满勤补算，显示「本月 139.0 杯」并折合金额
- **状态机**：上班中 / 午休中（不计薪）/ 待上班 / 已下班满勤入账 / 周末自动休假日
- **设置**：月薪（按到手口径填更真实）、计薪天数、上下班时间、午休扣除、锚定物品（macOS 另有开机自启）

### 计算口径

- 时薪 = 月薪 ÷ 每月计薪天数（默认 21.75）÷ 每日实际计薪时长（午休扣除）
- 满勤日薪 = 月薪 ÷ 计薪天数
- 今日已赚 = 已计薪秒数 × 每秒单价，封顶满勤日薪；数量 = 金额 ÷ 锚定物品单价
- 本月累计 = 本月已过工作日 × 满勤日薪 ＋ 今日实时已赚（周末自动跳过）

## 截图

**macOS 菜单栏弹层**（深色模式）：

![macOS 面板](assets/panel-dark.png)

**Windows 桌面版**：

![Windows 版](assets/screenshot-windows.png)

## 从源码构建

### macOS（原生 SwiftUI，无第三方依赖）

```bash
./build.sh                     # 产物: build/上班鼓励器.app
open build/上班鼓励器.app
```

调试参数：`CHEER_DEBUG_WINDOW=1` / `CHEER_DEBUG_SETTINGS=1` 启动可分别调出主面板 / 设置的独立调试窗口。

### Windows（Neutralino.js，最终包仅 ~2.6MB）

```bash
cd windows/workcheer-win
npx @neutralinojs/neu update   # 拉取各平台二进制
npx @neutralinojs/neu build --release
# 产物在 dist/上班鼓励器/，Windows 只需 上班鼓励器-win_x64.exe + resources.neu

# 可选：NSIS 安装器（需要 brew install makensis）
cd .. && makensis setup.nsi    # 产物 ../release/WorkCheer-Windows-v1.1-Setup.exe
```

## 项目结构

```
├── Sources/               macOS 版 Swift 源码（Engine / App / PanelView / SettingsView）
├── build.sh               macOS 构建脚本（swiftc + 手工组 .app bundle）
├── windows/
│   ├── workcheer-win/     Windows 版 Neutralino 项目（resources/index.html 是全部 UI 与逻辑）
│   └── setup.nsi          NSIS 安装器脚本
└── assets/                截图
```

## 更新日志

- 2026-11-06 v1.2：**兼容性修复（仅 macOS）**——清理 macOS 14+ API（新式 `onChange`），最低支持版本落到实处；构建改为 **Apple Silicon + Intel 通用二进制**，Intel 老机型也能装；系统要求：macOS 13.0（Ventura）及以上。Windows 版无改动。
- 2026-11-06 v1.1：**逻辑重做——锚定物品**（默认月薪 ¥10,000）。自定义一件物品（名称/单位/单价），工资按它换算：主数字从金额改成「今天赚了多少杯奶茶」，新增凑整倒计时（再过 X 分钟凑满 N 杯）、下班预期数量，本月累计与满勤同步改为物品数量口径，金额降级为折合小字。
- 2026-11-04 v1.0：首发。实时赚钱（每秒跳动）、下班倒计时、商品换算鼓励语、暂停计时、工时进度、本月累计按满勤补算、自定义赚回清单、午休不计薪；macOS 版含菜单栏常驻与开机自启，Windows 版含 NSIS 安装器与免安装包。

## 说明

- 本工具计算的是「到手的钱按时间摊薄」的心理账，图个开心和自觉，不构成任何劳动争议依据 🙂
- MIT 开源，欢迎 fork 修改自用
