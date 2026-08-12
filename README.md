# XcodeControl

XcodeControl is a lightweight macOS menu bar utility for building and running Xcode
projects without bringing the Xcode window to the front.

Open or drag in an `.xcodeproj` or `.xcworkspace`, choose a scheme and destination,
then build, install, launch, stop, or inspect logs from a compact menu bar utility.

## Features

- Open or drag in Xcode projects and workspaces
- Select shared schemes
- Run on simulators, connected devices, or This Mac
- Build, install, launch, stop, and cancel builds
- View readable error summaries and full build logs
- Access recent projects and common actions from the menu bar
- Configure build behavior, notifications, login launch, and global shortcuts

## Requirements

- macOS 26 or later
- A full Xcode installation
- Working Xcode command-line tools selected with `xcode-select`

Command Line Tools alone are not sufficient. XcodeControl calls the local
`xcodebuild`, `xcrun simctl`, and `xcrun devicectl` tools.

## Install

1. Download the latest notarized DMG from
   [GitHub Releases](https://github.com/JinjunHan/XcodeControl/releases).
2. Open the DMG and drag `XcodeControl.app` to `Applications`.
3. Launch XcodeControl from `Applications`.

XcodeControl is a menu bar app and does not show a Dock icon. On first use, macOS may
ask for notification permission only when build notifications are enabled. Global
shortcuts use the system hot-key API and do not require Accessibility permission.

## Privacy

XcodeControl has no account system, analytics, advertising, or telemetry. Project
bookmarks, recent projects, preferences, and build output remain on your Mac and are
not uploaded by XcodeControl.

## Distribution

Official binaries are signed with a Developer ID certificate, submitted to Apple
for notarization, and distributed through GitHub Releases. The app is not distributed
through the Mac App Store because its core workflow requires direct access to the
local Xcode command-line tools.

This repository is used for product information, downloads, release history, and
support. The XcodeControl source code is not published here.

## Support

Please use [GitHub Issues](https://github.com/JinjunHan/XcodeControl/issues) for bug
reports and support requests.
