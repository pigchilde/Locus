# Locus

<p align="center">
  <img src="Resources/LocusMark.png" width="128" height="128" alt="Locus Logo">
</p>

<p align="center">
  一款根据当前 Wi-Fi 或有线网络自动恢复 Mac 输出设备、系统音量和静音状态的原生 macOS 工具。
</p>

<p align="center">
  <a href="https://github.com/pigchilde/Locus/releases/latest">下载最新版本</a>
  ·
  <a href="INSTALL.md">安装与首次打开</a>
  ·
  <a href="https://github.com/pigchilde/Locus/actions/workflows/ci.yml">构建状态</a>
</p>

Locus 适合经常在家庭、办公室、咖啡店等网络环境之间切换的 Mac 用户。为不同 Wi-Fi 或有线网络保存声音规则后，Locus 会在网络变化时自动应用对应配置，减少重复调整，也避免切换环境后突然外放或音量不合适。

Locus 使用 Swift 和系统原生框架开发，不依赖第三方运行库，不包含服务端。网络规则、偏好设置和活动记录只保存在本机。

当前源码版本为 **1.0.3（构建 16）**。下载包的版本以 GitHub Releases 页面为准。

## 下载与安装

前往 [GitHub Releases](https://github.com/pigchilde/Locus/releases/latest) 下载 `Locus-版本号-macOS-universal.zip`。安装包同时支持 Apple Silicon 和 Intel Mac。

当前公开安装包使用 ad-hoc 签名，没有经过 Apple 公证。macOS 第一次打开时可能需要在“系统设置 → 隐私与安全性”中点击“仍要打开”。完整步骤参见 [安装与首次打开 Locus](INSTALL.md)。

## 功能

- 根据 Wi-Fi SSID 保存并匹配独立声音规则
- 检测有线以太网，为当前有线网络保存独立声音规则
- Wi-Fi 和网线同时连接时，跟随 macOS 主网络选择对应规则
- 设置目标系统音量
- 立即调整，或使用 1 秒、3 秒平滑过渡
- 可选切换系统默认输出设备
- 保持当前静音状态、取消静音或强制静音
- 为未保存的网络配置“其他网络”兜底规则
- 设置网络切换后的应用延迟
- 手动立即应用规则
- 在首页直接调整当前音量、切换静音状态
- 为 Wi-Fi 和有线规则修改显示名称，无需连接该网络
- 删除普通规则前确认，保留“其他网络”兜底规则
- 开启或关闭自动控制
- 登录 macOS 时自动启动
- 规则生效后发送可选的系统通知
- 查看本地活动记录和当前运行状态
- 跟随系统、浅色和深色三种外观模式
- 菜单栏常驻，可直接查看状态、管理规则和修改设置

## 界面

Locus 日常运行时是纯菜单栏应用，不会打开独立主窗口。点击菜单栏图标，在 368 × 580 pt 的面板中查看和管理声音规则。

首页左上角保留紫色 Logo，右上角为“自动控制”开关，开启显示蓝色，关闭显示灰色。当前网络与运行状态合并显示；声音区域提供输出设备、音量滑块及静音按钮；网络规则列表标记当前网络，并显示目标音量、静音或停用状态。底部提供最近活动和设置入口。

所有页面在同一个 Popover 中通过单层导航切换，使用 SwiftUI、系统字体和 SF Symbols，支持跟随系统、浅色和深色外观。

| 页面 | 主要操作 |
| --- | --- |
| 首页 | 查看当前网络与声音、开关自动控制、调整音量和静音、添加或打开规则 |
| 规则详情 | 修改显示名称、启用状态、声音参数和通知，立即应用或确认删除规则 |
| 添加规则 | 选择 Wi-Fi 或有线网络，填写网络信息并保存声音配置 |
| 设置 | 配置登录启动、切换延迟、未保存网络的处理方式、外观和权限 |
| 最近活动 | 查看最近 20 条网络变化、规则应用和错误记录 |
| Wi-Fi 名称权限 | 查看权限用途，允许读取或打开系统设置 |

## 添加与管理规则

### 为当前网络添加规则

1. 连接 Wi-Fi 或有线网络，点击菜单栏中的 Locus 图标。
2. 当前网络没有专用规则时，点击顶部网络卡片右侧的“添加规则”；也可以点击“网络规则”右上角的“＋ 添加”。
3. 当前 Wi-Fi 尚无规则时，添加页会自动带入它的名称。有线网络会带入当前网络标识，并显示网关和接口，可填写易于辨认的规则名称。
4. 设置输出设备和目标音量，点击“添加规则”。保存后可进入规则详情调整静音、过渡方式和通知。

也可以通过“＋ 添加”手动输入其他 Wi-Fi 的名称，提前创建规则；有线规则需要连接对应网络后创建。同一种网络类型下不允许重复添加相同的网络标识。无法读取 Wi-Fi 名称时，顶部会提供“授权”入口。

### 编辑名称与声音

点击当前网络卡片右侧的铅笔，或点击列表中的任一规则，进入规则详情。所有普通 Wi-Fi 和有线规则都可以修改显示名称，与当前是否连接无关。

显示名称仅用于辨认规则，不改变网络匹配条件。Wi-Fi 详情下方的“匹配 Wi-Fi”显示实际使用的原始 SSID；有线规则继续使用保存时的网络标识。修改显示名称后，仍会匹配原来的网络。

规则参数修改后自动保存。保存配置与应用到当前系统声音是两个操作；需要立刻调整声音时，点击底部“立即应用”。首页区分“规则已保存”和“规则已应用”。首页直接调整音量或静音不会修改规则中保存的目标配置。

### 删除与兜底规则

普通规则详情底部固定显示“删除规则”和“立即应用”。点击“删除规则”后，需要再次确认；取消不会删除。删除后，下次连接该网络时不再应用这条规则，是否使用兜底配置取决于对应设置。

“其他网络”是固定的兜底规则，不能删除或改名，可调整其声音参数和启用状态。要对没有专用规则的网络应用兜底配置，需要同时启用这条规则，并在“设置 → 网络切换 → 未保存的网络”中选择“应用其他网络规则”；选择“保持不变”则不应用兜底配置。

## 系统要求

- macOS 14 Sonoma 或更高版本

从源码构建还需要完整版 Xcode，以及 Swift 6 工具链；使用打包好的应用无需安装开发工具。

项目本身使用 Swift Package Manager 管理，Swift 源码采用 Swift 5 语言模式。

## 从源码构建

克隆仓库并进入项目目录后，先运行测试：

```bash
swift test
```

生成 Release 应用：

```bash
./Scripts/build_app.sh release
```

默认生成当前机器架构的应用。

生成同时支持 Apple Silicon 和 Intel 的 Universal 应用：

```bash
./Scripts/build_app.sh release universal
```

构建结果位于：

```text
dist/Locus.app
```

启动应用：

```bash
open dist/Locus.app
```

测试重新构建的版本前，请先通过“设置 → 退出 Locus”退出旧版本，再打开新应用。重新构建不会自动替换 `/Applications/Locus.app`；同一个应用标识只允许一个正式实例运行。

构建脚本会完成以下操作：

1. 使用 SwiftPM 编译 `Locus` 可执行程序。
2. 使用 `actool` 编译应用图标和 Asset Catalog。
3. 组装标准 macOS `.app` 目录。
4. 使用 ad-hoc 签名对本地应用进行签名并验证。

> 当前脚本和 GitHub Release 使用 ad-hoc 签名，未进行 Developer ID 签名、公证或 Stapling。首次安装说明见 [INSTALL.md](INSTALL.md)。

## 图标资源

README 与客户端首页统一使用最新的紫色流线「L + 声波」Logo，即透明背景的 `Resources/LocusMark.png`。应用图标和菜单栏图标由同一份已选定的源图生成：

| 资源 | 用途 |
| --- | --- |
| `Resources/LocusIconSource.png` | Logo 源图，用于生成下列资源 |
| `Resources/LocusMark.png` | 透明彩色 Logo，用于 README 和客户端首页 |
| `Resources/LocusDockIcon.png` | 带白色圆角底板的 macOS 应用图标 |
| `Resources/LocusMenuBarTemplate.png` | 随系统浅色、深色外观适配的单色菜单栏模板 |
| `Resources/Assets.xcassets/AppIcon.appiconset/` | 应用图标的各尺寸及 Retina 版本 |

更新源图后，运行以下命令同步生成全部图标资源：

```bash
./Scripts/generate_icon.sh
```

脚本保留已选定 Logo 的原图笔触，不重新绘制图案。构建应用时会将生成的资源一起打包；README 直接引用客户端同款透明 Logo，避免与带底板的应用图标混淆。

## 首次运行与权限

### 位置权限

macOS 要求应用获得位置权限后，才会向 CoreWLAN 提供当前 Wi-Fi 的 SSID。该权限用于识别 Wi-Fi 名称，Locus 不保存或上传实际地理位置。

仅使用有线网络时不需要位置权限。需要识别 Wi-Fi 时，可点击首页的“授权”，或进入“设置 → 权限 → Wi-Fi 名称 → 设置权限”，在说明页选择“允许读取”。选择“稍后”可返回首页。如果此前拒绝，可前往：

```text
系统设置 → 隐私与安全性 → 定位服务
```

### 通知权限

通知权限是可选的。只有启用规则通知后，Locus 才会在规则应用成功时发送本地系统通知。

### 登录时启动

“登录时打开”使用 macOS `SMAppService` 注册主应用，不会安装额外的后台守护程序。

## 数据与隐私

Locus 不需要账号，不连接服务器，也不包含遥测或分析 SDK。

所有规则、偏好设置和活动记录保存在：

```text
~/Library/Application Support/Locus/state.json
```

删除该文件会重置应用数据。建议在操作前退出 Locus；文件会在下次保存设置时重新创建。

## 工作原理

```text
SystemConfiguration 监听主网络变化，CoreWLAN 补充 Wi-Fi SSID
          ↓
AppModel 等待配置的网络稳定时间
          ↓
RuleMatcher 查找精确规则或兜底规则
          ↓
CoreAudioService 切换输出设备并调整音量、静音
          ↓
StateRepository 保存活动记录，按需发送系统通知
```

音量平滑调整使用 ease-out 插值，以约 30 FPS 从当前音量过渡到目标音量。网络变化时会取消前一项尚未完成的网络调度，手动应用规则时也会取消前一项手动音量任务。

## 技术栈

- Swift
- SwiftUI
- AppKit
- Combine
- Swift Concurrency
- CoreWLAN / SystemConfiguration
- CoreLocation
- CoreAudio / AudioToolbox
- ServiceManagement
- UserNotifications
- Swift Package Manager
- XCTest

项目不包含第三方 Swift Package。

## 项目结构

```text
Locus/
├── .github/                     CI、Issue 和 Pull Request 模板
├── CONTRIBUTING.md             贡献指南
├── INSTALL.md                  安装与首次打开说明
├── Package.swift                 SwiftPM 工程配置
├── PRODUCT.md                   产品定位与设计原则
├── RELEASING.md                版本发布流程
├── Resources/                   Info.plist、应用图标和资源目录
├── Scripts/                     构建、图标生成与界面截图脚本
├── SECURITY.md                 安全问题报告策略
├── Sources/
│   ├── LocusApp/                SwiftUI 应用、状态管理和系统服务
│   │   ├── PreviewState.swift   隔离真实数据和硬件操作的界面预览样例
│   │   ├── Services/            网络、音频、权限、通知和登录启动
│   │   └── Views/MenuBar/       菜单栏首页、规则、设置与活动页面
│   └── LocusCore/               数据模型、规则匹配和本地持久化
└── Tests/
    ├── LocusCoreTests/          匹配、网络标识、渐变与持久化测试
    └── LocusAppTests/           网络服务和规则管理流程回归测试
```

## 测试

运行全部测试：

```bash
swift test
```

当前测试主要覆盖：

- 精确规则和兜底规则的匹配优先级
- 停用规则、断网和缺失 SSID 的处理
- 有线与 Wi-Fi 的独立匹配、主网络选择和切换
- 有线网络标识在 DHCP 地址变化后的稳定性
- 旧版本 Wi-Fi 规则的兼容读取
- SSID 输入规范化
- 音量渐变与音量范围限制
- 规则、偏好设置和活动记录的 JSON 持久化
- 旧版本偏好数据的兼容读取
- 新 Wi-Fi 和有线规则的添加、修改、删除及重复添加保护
- 未连接的 Wi-Fi 规则改名后，显示名称持久化且原始网络仍可匹配
- 预览模式的音量、静音和自动控制不操作真实硬件

真实拔插网线、CoreWLAN、CoreAudio、系统权限和登录启动属于 macOS 系统集成，目前需要在真实设备上进行手动验证。

### 本地界面预览与截图

构建应用后，可以使用临时示例数据打开独立的开发预览窗口：

```bash
dist/Locus.app/Contents/MacOS/Locus --preview-window
```

例如，预览深色的未连接 Wi-Fi 规则详情：

```bash
LOCUS_PREVIEW_APPEARANCE=dark \
  dist/Locus.app/Contents/MacOS/Locus --preview-window --preview-route wifiRule
```

预览路由包括 `home`、`rule`、`wifiRule`、`addRule`、`settings`、`activity`、`permission`、`fallback` 和 `delete`。其中删除确认预览使用 `LOCUS_PREVIEW_ROUTE=delete`：

```bash
LOCUS_PREVIEW_ROUTE=delete \
  dist/Locus.app/Contents/MacOS/Locus --preview-window
```

生成浅色和深色页面及关键状态的原生截图：

```bash
./Scripts/capture_ui.sh
```

当前脚本生成 42 张 PNG，默认输出至 `designs/locus-native-home/native-qa/`。脚本不依赖已有设计稿，该目录会自动创建；`designs/` 为本地输出目录，不纳入版本控制。

预览使用临时状态文件，不会修改真实规则、系统音量、登录启动设置或请求系统权限。它用于检查页面和交互，不能代替真实网络切换、硬件音频和菜单栏首次打开的系统集成验证。详细验证记录见 [design-qa.md](design-qa.md)。

## 有线网络规则

连接网线后，首页显示当前有线网络或已保存的规则名称。尚无规则时，点击网络卡片右侧的“添加规则”，在添加页查看网关和接口，输入易于辨认的名称（例如“办公室”），设置声音并保存。之后即使未连接此网络，也可以在规则详情中修改显示名称。

有线规则优先使用 macOS 提供的网络签名（通常包含网关和网关硬件地址），不会绑定电脑的 DHCP IP 或某一个 USB 网卡。系统未提供签名时，使用网关和子网作为标识；仅 IPv6 的网络可退回使用网关。因此，没有签名且网关、子网相同的网络可能被视为同一环境；签名或网关更换后需要重新保存规则。系统稍后补齐签名时，标识也可能变化，建议网络稳定后再保存规则。

同时连接 Wi-Fi 与网线时，跟随 macOS 选择的主网络（优先 IPv4，IPv6-only 时使用 IPv6），不强制网线优先。位置权限仅用于读取 Wi-Fi 名称。有线网络可以使用“其他网络”兜底规则；断网或尚未获得可匹配的网络标识时保持声音不变。VPN、拨号和其他虚拟接口暂不作为独立规则类型。

## 当前限制

- SSID 使用区分大小写的精确匹配。
- 读取当前 SSID 必须获得 macOS 位置权限。
- 目标音频设备需要在规则生效时处于可用状态。
- 部分 HDMI、AirPlay 或专业音频设备可能不支持软件音量或静音控制。
- 规则较多时需要在菜单栏面板中滚动查看。
- GitHub Release 会自动生成未公证的 Universal ZIP，首次打开需要用户手动允许。

## 发布版本

维护者推送 `v*` 标签后，GitHub Actions 会自动运行测试、构建 Universal App、生成 SHA-256 校验文件并创建 Release。具体操作参见 [RELEASING.md](RELEASING.md)。

## 参与贡献

欢迎通过 Issue 和 Pull Request 参与改进。完整流程参见 [CONTRIBUTING.md](CONTRIBUTING.md)。提交代码前建议：

1. 先搜索已有 Issue，避免重复问题。
2. 对较大的功能或行为变更，先创建 Issue 讨论方案。
3. 从独立分支提交修改，避免混入无关变更。
4. 为核心业务逻辑补充或更新测试。
5. 确保 `swift test` 和 Release 构建通过。
6. 在 Pull Request 中说明修改原因、用户影响和验证方式；涉及界面时请附截图。

提交信息建议使用清晰的类型前缀，例如：

```text
feat: add rule import and export
fix: handle unavailable audio device
docs: update build instructions
test: cover disabled fallback rule
```

## 安全问题

如果发现可能影响用户隐私或系统安全的问题，请不要在公开 Issue 中披露完整利用细节。请按照 [SECURITY.md](SECURITY.md) 通过 GitHub 的私密漏洞报告功能联系维护者。

## 许可证

Locus 使用宽松的 [0BSD License](LICENSE) 开源。你可以将代码用于个人或商业用途，也可以复制、修改和再分发，且不要求保留署名；软件按原样提供，不附带任何担保。
