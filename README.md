# XcodeControl

[简体中文](#简体中文) | [English](#english)

## 简体中文

XcodeControl 是一款轻量级 macOS 菜单栏工具，无需将 Xcode 窗口切换到前台，
即可构建和运行 Xcode 项目。

打开或拖入 `.xcodeproj`、`.xcworkspace` 文件，选择 Scheme 和运行目标后，
即可通过紧凑的菜单栏界面执行构建、安装、启动、停止及日志查看等操作。

### 功能

- 打开或拖入 Xcode 项目和工作区
- 选择共享 Scheme
- 在模拟器、已连接设备或本机上运行
- 构建、安装、启动、停止应用，以及取消构建
- 查看清晰的错误摘要和完整构建日志
- 从菜单栏快速访问最近项目和常用操作
- 配置构建行为、通知、登录时启动和全局快捷键

### 系统要求

- macOS 26 或更高版本
- 完整安装的 Xcode
- 已通过 `xcode-select` 正确选择可用的 Xcode 命令行工具

仅安装 Command Line Tools 无法满足运行要求。XcodeControl 会调用本机的
`xcodebuild`、`xcrun simctl` 和 `xcrun devicectl` 工具。

### 安装

1. 从 [GitHub Releases](https://github.com/JinjunHan/XcodeControl/releases)
   下载最新的、已通过 Apple 公证的 DMG。
2. 打开 DMG，将 `XcodeControl.app` 拖入“应用程序”文件夹。
3. 从“应用程序”文件夹启动 XcodeControl。

XcodeControl 是菜单栏应用，不会显示 Dock 图标。只有在启用构建通知时，
macOS 才可能请求通知权限。全局快捷键使用系统热键 API，不需要辅助功能权限。

### 隐私

XcodeControl 不提供账户系统，也不包含分析、广告或遥测功能。项目书签、
最近使用的项目、偏好设置和构建输出均保留在您的 Mac 上，XcodeControl
不会上传这些内容。

### 分发说明

官方安装包使用 Developer ID 证书签名，并提交 Apple 公证，通过
[GitHub Releases](https://github.com/JinjunHan/XcodeControl/releases) 分发。
由于核心工作流程需要直接访问本机 Xcode 命令行工具，应用必须关闭
App Sandbox，因此不通过 Mac App Store 分发。

本仓库仅用于提供产品介绍、软件下载、版本记录和用户支持，不公开
XcodeControl 源代码。

### 支持

如需报告问题或寻求支持，请使用
[GitHub Issues](https://github.com/JinjunHan/XcodeControl/issues)。

---

## English

XcodeControl is a lightweight macOS menu bar utility for building and running Xcode
projects without bringing the Xcode window to the front.

Open or drag in an `.xcodeproj` or `.xcworkspace`, choose a scheme and destination,
then build, install, launch, stop, or inspect logs from a compact menu bar utility.

### Features

- Open or drag in Xcode projects and workspaces
- Select shared schemes
- Run on simulators, connected devices, or This Mac
- Build, install, launch, stop, and cancel builds
- View readable error summaries and full build logs
- Access recent projects and common actions from the menu bar
- Configure build behavior, notifications, login launch, and global shortcuts

### Requirements

- macOS 26 or later
- A full Xcode installation
- Working Xcode command-line tools selected with `xcode-select`

Command Line Tools alone are not sufficient. XcodeControl calls the local
`xcodebuild`, `xcrun simctl`, and `xcrun devicectl` tools.

### Install

1. Download the latest notarized DMG from
   [GitHub Releases](https://github.com/JinjunHan/XcodeControl/releases).
2. Open the DMG and drag `XcodeControl.app` to `Applications`.
3. Launch XcodeControl from `Applications`.

XcodeControl is a menu bar app and does not show a Dock icon. On first use, macOS may
ask for notification permission only when build notifications are enabled. Global
shortcuts use the system hot-key API and do not require Accessibility permission.

### Privacy

XcodeControl has no account system, analytics, advertising, or telemetry. Project
bookmarks, recent projects, preferences, and build output remain on your Mac and are
not uploaded by XcodeControl.

### Distribution

Official binaries are signed with a Developer ID certificate, submitted to Apple
for notarization, and distributed through
[GitHub Releases](https://github.com/JinjunHan/XcodeControl/releases). The app is not
distributed through the Mac App Store because its core workflow requires direct
access to the local Xcode command-line tools and therefore requires App Sandbox to
be disabled.

This repository is used for product information, downloads, release history, and
support. The XcodeControl source code is not published here.

### Support

Please use [GitHub Issues](https://github.com/JinjunHan/XcodeControl/issues) for bug
reports and support requests.
