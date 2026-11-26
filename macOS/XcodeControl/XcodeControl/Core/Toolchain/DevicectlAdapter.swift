//
//  DevicectlAdapter.swift
//  XcodeControl
//

import Foundation

/// 封装 `xcrun devicectl`：真机枚举、安装、启动、终止。
///
/// devicectl 只能把结构化结果写入文件而非 stdout，因此每个查询都要走临时文件。
enum DevicectlAdapter {

    private static var tempDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("XcodeControl", isDirectory: true)
    }

    private static func makeTempJSONURL(_ tag: String) throws -> URL {
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        return tempDirectory.appendingPathComponent("\(tag)-\(UUID().uuidString).json")
    }

    // MARK: - 枚举

    /// `xcrun devicectl list devices --json-output <path>`
    static func listDevices() async throws -> [RunDestination] {
        let output = try makeTempJSONURL("devices")
        defer { try? FileManager.default.removeItem(at: output) }

        let result = try await ProcessRunner.run(
            Toolchain.xcrunPath,
            ["devicectl", "list", "devices", "--quiet", "--json-output", output.path],
            environment: Toolchain.environment(),
            timeout: 60
        )
        guard result.isSuccess, let data = try? Data(contentsOf: output) else {
            throw DevicectlError.listFailed(result.combinedTrimmed)
        }
        return try parseDevices(data)
    }

    static func parseDevices(_ data: Data) throws -> [RunDestination] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = root["result"] as? [String: Any],
              let devices = result["devices"] as? [[String: Any]]
        else {
            throw DevicectlError.listFailed(L10n.t("无法解析 devicectl list devices 的输出"))
        }

        return devices.compactMap { device in
            guard let identifier = device["identifier"] as? String else { return nil }
            let properties = device["deviceProperties"] as? [String: Any] ?? [:]
            let hardware = device["hardwareProperties"] as? [String: Any] ?? [:]
            let connection = device["connectionProperties"] as? [String: Any] ?? [:]

            let name = properties["name"] as? String ?? L10n.t("未命名设备")
            let osVersion = properties["osVersionNumber"] as? String ?? ""
            let deviceType = hardware["deviceType"] as? String ?? ""
            let family = RunDestination.Family.fromHardwareDeviceType(deviceType)

            let rawPlatform = (hardware["platform"] as? String ?? "iOS").lowercased()
            var platform: RunDestination.Platform
            switch rawPlatform {
            case "ios": platform = family == .pad ? .iPadOS : .iOS
            case "tvos": platform = .tvOS
            case "watchos": platform = .watchOS
            case "xros", "visionos": platform = .visionOS
            case "macos": platform = .macOS
            default: platform = .iOS
            }

            // devicectl 会把历史上配对过的所有设备都列出来（tunnelState 为
            // unavailable / disconnected）。这些设备无法安装，列出来只会制造
            // 一个必然失败的选项，因此直接剔除——分组标题就叫「已连接设备」。
            let tunnelState = (connection["tunnelState"] as? String ?? "").lowercased()
            guard tunnelState == "connected" else { return nil }

            return RunDestination(
                id: identifier,
                name: name,
                source: .device,
                platform: platform,
                osVersion: osVersion,
                state: .connected,
                deviceFamily: family
            )
        }
    }

    // MARK: - 安装与启动

    static func install(deviceID: String, appPath: URL) async throws {
        let output = try makeTempJSONURL("install")
        defer { try? FileManager.default.removeItem(at: output) }

        let result = try await ProcessRunner.run(
            Toolchain.xcrunPath,
            ["devicectl", "device", "install", "app",
             "--device", deviceID, appPath.path,
             "--quiet", "--json-output", output.path],
            environment: Toolchain.environment(),
            timeout: 600
        )
        guard result.isSuccess else {
            throw DevicectlError.installFailed(result.combinedTrimmed)
        }
    }

    /// 附着控制台启动，命令会一直等待 App 退出。
    static func launchAttached(
        deviceID: String,
        bundleID: String,
        onLine: @escaping @Sendable (String, StreamKind) -> Void,
        onExit: @escaping @Sendable (Int32) -> Void
    ) throws -> RunningProcess {
        try ProcessRunner.stream(
            Toolchain.xcrunPath,
            ["devicectl", "device", "process", "launch",
             "--device", deviceID,
             "--terminate-existing", "--console", bundleID],
            environment: Toolchain.environment(),
            onLine: onLine,
            onExit: onExit
        )
    }

    /// 不附着控制台的启动，返回 App 的 PID。
    static func launchDetached(deviceID: String, bundleID: String) async throws -> Int32? {
        let output = try makeTempJSONURL("launch")
        defer { try? FileManager.default.removeItem(at: output) }

        let result = try await ProcessRunner.run(
            Toolchain.xcrunPath,
            ["devicectl", "device", "process", "launch",
             "--device", deviceID, "--terminate-existing",
             "--quiet", "--json-output", output.path, bundleID],
            environment: Toolchain.environment(),
            timeout: 300
        )
        guard result.isSuccess else {
            throw DevicectlError.launchFailed(result.combinedTrimmed)
        }
        guard let data = try? Data(contentsOf: output),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let payload = root["result"] as? [String: Any],
              let process = payload["process"] as? [String: Any],
              let pid = process["processIdentifier"] as? Int
        else { return nil }
        return Int32(pid)
    }

    // MARK: - 终止

    /// devicectl 没有 terminate 子命令：先查 PID 再发信号。
    static func terminate(deviceID: String, bundleID: String) async {
        guard let pid = try? await processIdentifier(deviceID: deviceID, bundleID: bundleID)
        else { return }
        _ = try? await ProcessRunner.run(
            Toolchain.xcrunPath,
            ["devicectl", "device", "process", "signal",
             "--device", deviceID, "--pid", String(pid), "--signal", "SIGKILL", "--quiet"],
            environment: Toolchain.environment(),
            timeout: 60
        )
    }

    static func processIdentifier(deviceID: String, bundleID: String) async throws -> Int32? {
        let output = try makeTempJSONURL("processes")
        defer { try? FileManager.default.removeItem(at: output) }

        let result = try await ProcessRunner.run(
            Toolchain.xcrunPath,
            ["devicectl", "device", "info", "processes",
             "--device", deviceID, "--quiet", "--json-output", output.path],
            environment: Toolchain.environment(),
            timeout: 90
        )
        guard result.isSuccess,
              let data = try? Data(contentsOf: output),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let payload = root["result"] as? [String: Any],
              let processes = payload["runningProcesses"] as? [[String: Any]]
        else { return nil }

        // executable 形如 file:///private/var/containers/Bundle/Application/<UUID>/App.app/App
        for process in processes {
            guard let executable = process["executable"] as? String else { continue }
            if executable.contains(bundleID) || executable.contains("/\(bundleID).app/") {
                return (process["processIdentifier"] as? Int).map(Int32.init)
            }
        }
        return nil
    }
}

enum DevicectlError: LocalizedError {
    case listFailed(String)
    case installFailed(String)
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .listFailed(let d):
            d.isEmpty ? L10n.t("读取真机列表失败") : d
        case .installFailed(let d):
            ErrorTranslator.translate(d) ?? L10n.t("安装到设备失败：%@", d)
        case .launchFailed(let d):
            ErrorTranslator.translate(d) ?? L10n.t("在设备上启动 App 失败：%@", d)
        }
    }
}
