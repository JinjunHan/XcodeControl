<div align="center">

# XcodeControl

**Build and run your Xcode project from a floating window — never open Xcode, never switch windows**

[简体中文](README.md) | English

[![Release](https://img.shields.io/github/v/release/JinjunHan/XcodeControl?label=release&color=0A84FF)](https://github.com/JinjunHan/XcodeControl/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-26%2B-000000?logo=apple&logoColor=white)](#requirements)
[![Download DMG](https://img.shields.io/badge/download-DMG-34C759)](https://github.com/JinjunHan/XcodeControl/releases/latest)

<img src="screenshots/float.png" width="480" alt="The XcodeControl floating window">

</div>

## Why XcodeControl

In the vibe-coding era, more and more of your code is written by AI, and Xcode is left
doing exactly one job for you: **Run**.

Yet that single step still costs you a trip to Xcode — switch apps, wait for it to
respond, click the run button, switch back. Dozens of times a day, and every one of
them breaks your flow.

XcodeControl moves that step into a floating window that is always within reach:
**press ⌥⌘R and it builds, installs, and launches.** Keep coding with your AI while
your app lands on the device, without your attention ever leaving the editor.

## Features

| Feature | What it does |
| :--- | :--- |
| 🪟 **Always-there floating window** | Sits above your code: pick a project and a destination, then build, install, launch, stop, or cancel — no need to bring up Xcode |
| ⌨️ **Global shortcut** | <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>R</kbd> by default, works from any app, and can be changed |
| 📱 **iOS and macOS** | Run on iOS simulators, connected physical devices, or straight to This Mac |
| 🗂️ **Multi-project management** | Drag in an `.xcodeproj` / `.xcworkspace` to add it, then switch between projects at any time |
| 🧾 **Build results at a glance** | A readable error summary when a build fails, plus the full build log on demand |
| 🔒 **Entirely local** | No accounts, analytics, or telemetry — projects and build output stay on your Mac |

## Screenshots

<div align="center">
  <img src="screenshots/projects.png" width="840" alt="Project list in Settings">
  <p><em>Settings window: manage the project list and configure general, build, behavior, and location preferences.</em></p>
</div>

## Getting started

1. Download the latest notarized DMG from
   [GitHub Releases](https://github.com/JinjunHan/XcodeControl/releases/latest).
2. Open the DMG, drag `XcodeControl.app` to `Applications`, and launch it.
3. Open or drag in an `.xcodeproj` or `.xcworkspace`, then choose a scheme and
   destination.
4. Press <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>R</kbd> to build and run.

XcodeControl is a menu bar app and does not show a Dock icon. macOS may ask for
notification permission only when build notifications are enabled. Global shortcuts use
the system hot-key API and do not require Accessibility permission.

## Requirements

- macOS 26 or later
- A full Xcode installation
- Working Xcode command-line tools selected with `xcode-select`

Command Line Tools alone are not sufficient. XcodeControl calls the local
`xcodebuild`, `xcrun simctl`, and `xcrun devicectl` tools.

## Privacy

No accounts, no analytics, no advertising, no telemetry. Your projects, preferences, and
build output never leave your Mac.

## About this repository

This repository is used for product information, downloads, and release history. The
XcodeControl source code is not published here.

Official builds are signed with a Developer ID certificate and notarized by Apple.
XcodeControl is not distributed through the Mac App Store because it calls the local
Xcode command-line tools directly, which requires App Sandbox to be disabled.

## Support

Please use [GitHub Issues](https://github.com/JinjunHan/XcodeControl/issues) for bug
reports and support requests.
