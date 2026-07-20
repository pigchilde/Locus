# Locus

<p align="center">
  <img src="Resources/LocusDockIcon.png" width="128" height="128" alt="Locus 图标">
</p>

<p align="center">
  一款根据当前 Wi-Fi 自动恢复 Mac 输出设备、系统音量和静音状态的原生 macOS 工具。
</p>

<p align="center">
  <a href="https://github.com/pigchilde/Locus/releases/latest">下载最新版本</a>
  ·
  <a href="INSTALL.md">安装与首次打开</a>
  ·
  <a href="https://github.com/pigchilde/Locus/actions/workflows/ci.yml">构建状态</a>
</p>

Locus 适合经常在家庭、办公室、咖啡店等网络环境之间切换的 Mac 用户。为不同 Wi-Fi 保存声音规则后，Locus 会在网络变化时自动应用对应配置，减少重复调整，也避免切换环境后突然外放或音量不合适。

Locus 使用 Swift 和系统原生框架开发，不依赖第三方运行库，不包含服务端。Wi-Fi 规则、偏好设置和活动记录只保存在本机。

## 下载与安装

前往 [GitHub Releases](https://github.com/pigchilde/Locus/releases/latest) 下载 `Locus-版本号-macOS-universal.zip`。安装包同时支持 Apple Silicon 和 Intel Mac。

当前公开安装包使用 ad-hoc 签名，没有经过 Apple 公证。macOS 第一次打开时可能需要在“系统设置 → 隐私与安全性”中点击“仍要打开”。完整步骤参见 [安装与首次打开 Locus](INSTALL.md)。

## 功能

- 根据 Wi-Fi SSID 保存并匹配独立声音规则
- 设置目标系统音量
- 立即调整，或使用 1 秒、3 秒平滑过渡
- 可选切换系统默认输出设备
- 保持当前静音状态、取消静音或强制静音
- 为未保存的网络配置“其他网络”兜底规则
- 设置网络切换后的应用延迟
- 手动立即应用规则
- 开启或关闭自动控制
- 登录 macOS 时自动启动
- 规则生效后发送可选的系统通知
- 查看本地活动记录和当前运行状态
- 跟随系统、浅色和深色三种外观模式
- 菜单栏常驻，可快速打开主窗口或退出应用

## 界面

应用主要包含三个页面：

- **概览**：查看当前 Wi-Fi、输出设备、系统音量、匹配规则和最近活动。
- **Wi-Fi 规则**：添加、编辑、启用、停用、立即应用或删除规则。
- **偏好设置**：配置外观、自动控制、登录启动、切换延迟、兜底行为和系统权限。

界面使用 SwiftUI 和 macOS 原生控件构建，并根据窗口宽度在分栏与紧凑布局之间切换。

## 系统要求

- macOS 14 Sonoma 或更高版本
- 完整版 Xcode，以及 Swift 6 工具链

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

构建脚本会完成以下操作：

1. 使用 SwiftPM 编译 `Locus` 可执行程序。
2. 使用 `actool` 编译应用图标和 Asset Catalog。
3. 组装标准 macOS `.app` 目录。
4. 使用 ad-hoc 签名对本地应用进行签名并验证。

> 当前脚本和 GitHub Release 使用 ad-hoc 签名，未进行 Developer ID 签名、公证或 Stapling。首次安装说明见 [INSTALL.md](INSTALL.md)。

## 首次运行与权限

### 位置权限

macOS 要求应用获得位置权限后，才会向 CoreWLAN 提供当前 Wi-Fi 的 SSID。Locus 不读取、保存或上传实际地理位置。

首次运行时，请在应用中允许位置权限。如果此前拒绝，可前往：

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
CoreWLAN 监听 SSID 变化
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
- CoreWLAN
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
├── Scripts/                     构建与图标生成脚本
├── SECURITY.md                 安全问题报告策略
├── Sources/
│   ├── LocusApp/                SwiftUI 应用、状态管理和系统服务
│   │   ├── Services/            Wi-Fi、音频、权限、通知和登录启动
│   │   └── Views/               概览、规则与偏好设置页面
│   └── LocusCore/               数据模型、规则匹配和本地持久化
└── Tests/
    └── LocusCoreTests/          核心业务单元测试
```

## 测试

运行全部测试：

```bash
swift test
```

当前测试主要覆盖：

- 精确规则和兜底规则的匹配优先级
- 停用规则和缺失 SSID 的处理
- SSID 输入规范化
- 音量渐变与音量范围限制
- 规则、偏好设置和活动记录的 JSON 持久化
- 旧版本偏好数据的兼容读取

CoreWLAN、CoreAudio、系统权限和登录启动属于 macOS 系统集成，目前需要在真实设备上进行手动验证。

## 当前限制

- SSID 使用区分大小写的精确匹配。
- 读取当前 SSID 必须获得 macOS 位置权限。
- 目标音频设备需要在规则生效时处于可用状态。
- 部分 HDMI、AirPlay 或专业音频设备可能不支持软件音量或静音控制。
- 菜单栏当前只提供显示主界面和退出功能。
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
