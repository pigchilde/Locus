# 发布 Locus

Locus 使用 GitHub Actions 生成没有 Apple Developer ID 签名的 Universal ZIP。推送符合 `v*` 格式的标签后，Release Workflow 会运行测试、构建双架构应用、生成 SHA-256 校验文件并创建 GitHub Release。

## 发布前检查

1. 更新 `Resources/Info.plist`：
   - `CFBundleShortVersionString`：公开版本，例如 `1.0.0`
   - `CFBundleVersion`：递增的内部构建号
2. 确保 README、安装说明和用户可见行为一致。
3. 本地验证：

```bash
swift test
./Scripts/build_app.sh release universal
lipo -archs dist/Locus.app/Contents/MacOS/Locus
```

最后一条命令应同时输出 `arm64` 和 `x86_64`。

## 创建版本

提交版本变更并推送 `main` 后创建附注标签：

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

标签中的版本号必须与 `CFBundleShortVersionString` 完全一致，否则 Workflow 会停止发布。

运行进度可以在仓库的 **Actions → Release** 页面查看。成功后，Release 会包含：

```text
Locus-v1.0.0-macOS-universal.zip
SHA256SUMS.txt
```

Release Notes 由 GitHub 根据上一个版本以来的提交自动生成，可以在发布后继续编辑。

## 发布失败

修复问题后，不要移动已经公开使用的版本标签。尚未公开的失败标签可以删除后重新创建；已经公开的版本应增加补丁版本，例如从 `v1.0.0` 更新为 `v1.0.1`。

## 无证书安装提示

当前发布包使用 ad-hoc 签名，没有经过 Apple 公证。Release 说明和 README 必须保留指向 [INSTALL.md](INSTALL.md) 的首次打开说明。
