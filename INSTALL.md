# 安装与首次打开 Locus

Locus 的 GitHub Release 安装包使用 ad-hoc 签名，没有经过 Apple Developer ID 签名和公证。因此 macOS 第一次打开时可能会拦截应用。按照下面的步骤仅放行一次，之后即可像普通应用一样启动。

> 请只安装从 [pigchilde/Locus Releases](https://github.com/pigchilde/Locus/releases) 下载的文件。不要对来源不明的应用执行终端放行命令。

## 1. 下载并安装

1. 打开 [最新版本下载页](https://github.com/pigchilde/Locus/releases/latest)。
2. 下载名称类似 `Locus-v1.0.0-macOS-universal.zip` 的文件。
3. 双击 ZIP 解压。
4. 将 `Locus.app` 拖入“应用程序”文件夹。

安装包同时支持 Apple Silicon 和 Intel Mac，无需区分芯片类型。

## 2. 第一次打开

在“应用程序”中双击 `Locus`。如果 macOS 提示无法验证开发者或无法检查是否包含恶意软件，请关闭提示，不要点击“移到废纸篓”。

然后打开：

```text
系统设置 → 隐私与安全性 → 安全性
```

找到关于 Locus 被阻止的提示，点击“仍要打开”，按照系统提示使用密码或 Touch ID 确认，再次点击“打开”。这个操作通常只需要执行一次。

## 3. 如果没有出现“仍要打开”

可以只对 Locus 移除下载隔离标记。打开“终端”，复制并执行：

```bash
xattr -dr com.apple.quarantine "/Applications/Locus.app"
open "/Applications/Locus.app"
```

该命令只处理 `/Applications/Locus.app`，不会关闭整个系统的 Gatekeeper。请勿使用全局禁用 macOS 安全检查的命令。

## 4. 允许读取 Wi-Fi 名称

Locus 第一次运行时会申请位置权限。macOS 要求获得该权限后，CoreWLAN 才能提供当前 Wi-Fi 的 SSID。

Locus 不读取、保存或上传实际地理位置。若之前拒绝授权，可以前往：

```text
系统设置 → 隐私与安全性 → 定位服务 → Locus
```

## 5. 校验下载文件（可选）

每个 Release 都会附带 `SHA256SUMS.txt`。在下载目录运行：

```bash
shasum -a 256 "Locus-v1.0.0-macOS-universal.zip"
```

将输出与 `SHA256SUMS.txt` 中的值比较，一致表示文件在下载过程中没有发生变化。

## 常见问题

### 应用提示目标输出设备不可用

确认对应的蓝牙、HDMI、AirPlay 或外接音频设备已经连接，再重新应用规则。

### 看不到当前 Wi-Fi 名称

检查 Locus 的位置权限，然后回到应用中点击刷新。读取 SSID 是 macOS 的权限要求，与 GPS 定位无关。

### 更新版本

退出 Locus，下载新版本并用新的 `Locus.app` 替换“应用程序”中的旧版本即可。规则和偏好设置保存在 `~/Library/Application Support/Locus/state.json`，更新应用不会删除这些数据。
