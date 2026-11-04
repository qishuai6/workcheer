# 上班鼓励器 · WorkCheer

把工资实时折算到秒，看着钱一格格涨的桌面小工具。看看自己每一秒值多少钱，今天已经赚回了一杯奶茶还是一顿火锅。

**支持 macOS（菜单栏常驻）和 Windows（桌面窗口），数据全部留在本机，不联网、不上传。**

## 下载安装

到 [Releases](https://github.com/qishuai6/workcheer/releases/latest) 页面下载对应平台的包：

| 平台 | 文件 | 说明 |
|---|---|---|
| macOS | `WorkCheer-macOS-v1.0.zip` | 解压 → 把「上班鼓励器.app」拖进「应用程序」→ 打开 |
| Windows | `WorkCheer-Windows-v1.0-Setup.exe` | 双击安装，装完自动运行，带卸载器 |
| Windows | `WorkCheer-Windows-v1.0-portable.zip` | 免安装版：解压后双击「上班鼓励器.exe」 |

> **macOS 首次打开提示「无法验证开发者」**：右键 App → 「打开」→ 再点「打开」；
> 或终端执行 `xattr -cr /Applications/上班鼓励器.app`。
>
> **Windows 首次打开 SmartScreen 蓝色警告**：点「更多信息」→「仍要运行」。

## 功能

- **实时赚钱**：今日已赚按秒跳动（4 位小数），显示赚钱速度 ¥/秒
- **下班倒计时**：距离下班还有多久，一眼看清今天还剩多少「生产时间」
- **商品换算**：「已经赚回『一顿火锅』」「再过 1 小时 41 分，『一双跑鞋』就赚回来了」——清单从奶茶到 MacBook Pro 可自由增删改
- **暂停计时**：时间冻结、金额停涨（摸鱼不扣钱的合法遮羞布）
- **工时进度条**：已工作 / 总计薪时长
- **本月累计**：已过的日子按满勤补算，只计已赚、不含亏损
- **状态机**：上班中 / 午休中（不计薪）/ 待上班 / 已下班满勤入账 / 周末自动休假日
- **设置**：月薪（按到手口径填更真实）、计薪天数、上下班时间、午休扣除、开机自启（macOS）

### 计算口径

- 时薪 = 月薪 ÷ 每月计薪天数（默认 21.75）÷ 每日实际计薪时长（午休扣除）
- 满勤日薪 = 月薪 ÷ 计薪天数
- 今日已赚 = 已计薪秒数 × 每秒单价，封顶满勤日薪
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
cd .. && makensis setup.nsi    # 产物 ../release/WorkCheer-Windows-v1.0-Setup.exe
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

- 2026-11-04 v1.0：首发。实时赚钱（每秒跳动）、下班倒计时、商品换算鼓励语、暂停计时、工时进度、本月累计按满勤补算、自定义赚回清单、午休不计薪；macOS 版含菜单栏常驻与开机自启，Windows 版含 NSIS 安装器与免安装包。

## 说明

- 本工具计算的是「到手的钱按时间摊薄」的心理账，图个开心和自觉，不构成任何劳动争议依据 🙂
- MIT 开源，欢迎 fork 修改自用
