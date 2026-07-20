# Locus

Locus 是一款原生 macOS 工具：连接不同 Wi‑Fi 时，自动恢复对应的输出设备、系统音量和静音状态。

## 功能

- 按 Wi‑Fi SSID 保存独立音量规则
- 网络变化后自动匹配规则，并支持 0 / 1 / 3 秒平滑调整
- 可选切换系统默认输出设备
- 支持保持、取消或强制静音
- 菜单栏快速调整、暂停和恢复自动控制
- 支持跟随系统、浅色与深色三种界面配色
- 登录时启动、系统通知和本地活动记录
- 规则与记录仅保存在 `~/Library/Application Support/Locus/state.json`

## 开发与测试

```bash
swift test
```

应用图标资源位于 `Resources/Assets.xcassets`。生成应用包：

```bash
./Scripts/build_app.sh release
open dist/Locus.app
```

最终应用位于 `dist/Locus.app`。首次运行时需允许位置权限，macOS 才会向应用提供当前 Wi‑Fi 名称。
