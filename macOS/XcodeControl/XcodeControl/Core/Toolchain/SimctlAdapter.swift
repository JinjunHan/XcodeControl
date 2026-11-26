//
//  SimctlAdapter.swift
//  XcodeControl
//

import Foundation

/// 封装 `xcrun simctl`：模拟器枚举、启动、安装、运行、终止。
enum SimctlAdapter {

    // MARK: - 枚举

    /// `xcrun simctl list devices --json available`
    static func listDevices() async throws -> [RunDestination] {
        let result = try await ProcessRunner.run(
            Toolchain.xcrunPath,
            ["simctl", "list", "devices", "--json", "available"],
            environment: Toolchain.environment(),
            timeout: 60
        )
        guard result.isSuccess else {
            throw SimctlError.listFailed(result.combinedTrimmed)
        }
        return try parseDevices(result.stdout)
    }

    static func parseDevices(_ json: String) throws -> [RunDestination] {
        guard let start = json.firstIndex(of: "{"),
              let data = String(json[start...]).data(using: .utf8),
              let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let byRuntime = root["devices"] as? [String: [[String: Any]]]
        else {
            throw SimctlError.listFailed(L10n.t("无法解析 simctl list devices 的输出"))
        }

        var destinations: [RunDestination] = []
        for (runtimeID, devices) in byRuntime {
            guard let runtime = RunDestination.Platform.fromRuntimeIdentifier(runtimeID) else { continue }
            for device in devices {
                // 过滤掉未安装 runtime 对应的条目
                if let available = device["isAvailable"] as? Bool, available == false { continue }
                guard let udid = device["udid"] as? String,
                      let name = device["name"] as? String
                else { continue }

                let rawState = device["state"] as? String ?? "Shutdown"
                let typeID = device["deviceTypeIdentifier"] as? String ?? ""
                var family = RunDestination.Family.fromDeviceTypeIdentifier(typeID)
                if typeID.isEmpty { family = .fromDeviceTypeIdentifier(name) }

                // iPad 在 iOS runtime 下运行，展示上归为 iPadOS
                let platform: RunDestination.Platform =
                    (runtime.platform == .iOS && family == .pad) ? .iPadOS : runtime.platform

                destinations.append(
                    RunDestination(
                        id: udid,
                        name: name,
                        source: .simulator,
                        platform: platform,
                        osVersion: runtime.version,
                        state: rawState.caseInsensitiveCompare("Booted") == .orderedSame ? .booted : .shutdown,
                        deviceFamily: family
                    )
                )
            }
        }
        return destinations
    }

    // MARK: - 生命周期

    /// 启动模拟器。对已启动的设备重复 boot 会返回 149/"Unable to boot device in current state: Booted"，
    /// 这里视为成功。
    static func boot(udid: String) async throws {
        let result = try await ProcessRunner.run(
            Toolchain.xcrunPath, ["simctl", "boot", udid],
            environment: Toolchain.environment(),
            timeout: 120
        )
        if result.isSuccess { return }
        let message = result.combinedTrimmed
        if message.localizedCaseInsensitiveContains("current state: Booted")
            || message.localizedCaseInsensitiveContains("Unable to boot device in current state") {
            return
        }
        throw SimctlError.bootFailed(message)
    }

    /// 把 Simulator.app 带到前台并切到目标设备。
    static func openSimulatorApp(udid: String) async {
        _ = try? await ProcessRunner.run(
            Toolchain.openPath,
            ["-a", "Simulator", "--args", "-CurrentDeviceUDID", udid],
            environment: Toolchain.environment(),
            timeout: 30
        )
    }

    /// 等待设备进入 Booted 状态（boot 命令返回后 CoreSimulator 仍需要一点时间）。
    static func waitUntilBooted(udid: String, timeout: TimeInterval = 60) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let devices = try? await listDevices()
            if devices?.first(where: { $0.id == udid })?.state == .booted { return }
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
        }
        throw SimctlError.bootFailed(L10n.t("模拟器启动超时"))
    }

    static func install(udid: String, appPath: URL) async throws {
        let result = try await ProcessRunner.run(
            Toolchain.xcrunPath, ["simctl", "install", udid, appPath.path],
            environment: Toolchain.environment(),
            timeout: 180
        )
        guard result.isSuccess else {
            throw SimctlError.installFailed(result.combinedTrimmed)
        }
    }

    /// 启动并附着控制台输出。`--console-pty` 会让命令一直不返回，
    /// 因此只在需要实时日志时使用，并以返回的句柄作为「App 正在运行」的凭据。
    static func launchAttached(
        udid: String,
        bundleID: String,
        onLine: @escaping @Sendable (String, StreamKind) -> Void,
        onExit: @escaping @Sendable (Int32) -> Void
    ) throws -> RunningProcess {
        try ProcessRunner.stream(
            Toolchain.xcrunPath,
            ["simctl", "launch", "--console-pty", "--terminate-running-process", udid, bundleID],
            environment: Toolchain.environment(),
            onLine: onLine,
            onExit: onExit
        )
    }

    /// 不附着控制台的启动，返回 App 的 PID。
    static func launchDetached(udid: String, bundleID: String) async throws -> Int32? {
        let result = try await ProcessRunner.run(
            Toolchain.xcrunPath,
            ["simctl", "launch", "--terminate-running-process", udid, bundleID],
            environment: Toolchain.environment(),
            timeout: 120
        )
        guard result.isSuccess else {
            throw SimctlError.launchFailed(result.combinedTrimmed)
        }
        // 输出形如 `com.example.App: 12345`
        let pid = result.stdout
            .split(separator: "\n").last
            .flatMap { $0.split(separator: ":").last }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .flatMap { Int32($0) }
        return pid
    }

    static func terminate(udid: String, bundleID: String) async {
        _ = try? await ProcessRunner.run(
            Toolchain.xcrunPath, ["simctl", "terminate", udid, bundleID],
            environment: Toolchain.environment(),
            timeout: 30
        )
    }
}

enum SimctlError: LocalizedError {
    case listFailed(String)
    case bootFailed(String)
    case installFailed(String)
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .listFailed(let d):
            d.isEmpty ? L10n.t("读取模拟器列表失败") : d
        case .bootFailed(let d):
            L10n.t("启动模拟器失败：%@", d)
        case .installFailed(let d):
            ErrorTranslator.translate(d) ?? L10n.t("安装到模拟器失败：%@", d)
        case .launchFailed(let d):
            ErrorTranslator.translate(d) ?? L10n.t("在模拟器上启动 App 失败：%@", d)
        }
    }
}
