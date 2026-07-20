# 为 Locus 做贡献

感谢你愿意帮助改进 Locus。Bug 修复、测试、文档改进和符合产品定位的新功能都很欢迎。

## 开始之前

- 搜索已有 Issue 和 Pull Request，避免重复工作。
- 小型修复可以直接提交 Pull Request。
- 较大的功能、架构调整或用户行为变化，请先创建 Issue 讨论范围和方案。
- 安全问题不要提交公开 Issue，请按照 [SECURITY.md](SECURITY.md) 私密报告。

## 开发环境

- macOS 14 或更高版本
- 完整版 Xcode
- Swift 6 工具链

克隆仓库后运行：

```bash
swift test
swift build -c release --product Locus
```

需要验证完整应用包时运行：

```bash
./Scripts/build_app.sh release
open dist/Locus.app
```

生成的 `.build/`、`dist/`、`.swiftpm/` 和 Xcode 本地状态不应提交。

## 修改原则

- 保持 Locus 本地优先，不新增不必要的网络请求、账号体系或遥测。
- 保持 macOS 原生交互和现有项目结构。
- 将可独立测试的模型和业务逻辑放在 `LocusCore`。
- 将 CoreWLAN、CoreAudio、通知和权限等系统交互封装在 `LocusApp/Services`。
- 不在 Issue、测试数据、截图或日志中提交真实的敏感 SSID 和设备信息。
- 如果修改了用户行为、构建方式或系统要求，请同步更新 README。

## 测试

提交前至少运行：

```bash
swift test
swift build -c release --product Locus
```

涉及 CoreWLAN、CoreAudio、位置权限、通知或登录启动时，还需要在真实 Mac 上手动验证。请在 Pull Request 中记录系统版本、设备类型和验证结果。

## 提交信息

建议使用简洁的 Conventional Commits 风格：

```text
feat: add rule import and export
fix: handle unavailable audio device
docs: update build instructions
test: cover disabled fallback rule
refactor: simplify audio property access
```

一次提交尽量只处理一个主题，不要提交编译产物或无关格式化。

## Pull Request

Pull Request 应当包含：

- 修改原因和解决的问题
- 用户可见影响
- 测试与手动验证结果
- 相关 Issue
- 界面变化前后的截图（如适用）

维护者可能会要求缩小范围、补充测试或调整实现，以保持应用稳定和项目结构清晰。

## 贡献许可

提交 Issue、代码或文档时，请确保内容由你原创，或者你有权以本项目的 [0BSD License](LICENSE) 提供。提交 Pull Request 即表示你同意将该贡献按 0BSD License 授权。
