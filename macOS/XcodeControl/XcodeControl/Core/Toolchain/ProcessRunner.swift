//
//  ProcessRunner.swift
//  XcodeControl
//

import Darwin
import Foundation

enum StreamKind: Sendable {
    case stdout
    case stderr
}

struct ProcessResult: Sendable {
    let exitCode: Int32
    let stdout: String
    let stderr: String

    var isSuccess: Bool { exitCode == 0 }

    /// stderr 优先的可读输出，用于错误提示
    var combinedTrimmed: String {
        let err = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        if !err.isEmpty { return err }
        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ProcessRunnerError: LocalizedError {
    case launchFailed(command: String, reason: String)
    case timedOut(command: String, seconds: TimeInterval)
    case nonZeroExit(command: String, code: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case .launchFailed(let command, let reason):
            L10n.t("无法执行 %@：%@", command, reason)
        case .timedOut(let command, let seconds):
            L10n.t("%@ 执行超时（%ds）", command, Int(seconds))
        case .nonZeroExit(let command, let code, let output):
            output.isEmpty ? L10n.t("%@ 退出码 %d", command, code) : output
        }
    }
}

// MARK: - 运行中的进程句柄

/// 一个正在运行的子进程，支持优雅取消。
///
/// 取消依赖两个互补的机制，缺一不可：
///
/// 1. **先 SIGINT**。现代 xcodebuild 只是 XCBBuildService 的客户端，真正的
///    编译器（swift-frontend）由那个 launchd 守护进程派生，各自独立成组，
///    不在我们的进程组里——想靠信号直接杀是杀不到的。但 xcodebuild 收到
///    SIGINT 会通知 XCBBuildService 取消构建，实测 12 个 swift-frontend 会
///    在 0.6s 内全部停止。所以 SIGINT + 足够的宽限期才是停止构建的正解，
///    过早 SIGKILL 反而会跳过这次握手。
/// 2. **再 SIGKILL 兜底**。主进程组覆盖普通 fork 路径；SwiftPM 的 git
///    可能另建进程组，因此取消前还会记录后代 PID/PGID，宽限期后一起清理。
final class RunningProcess: @unchecked Sendable {

    let commandDescription: String
    let processIdentifier: Int32

    /// 子进程所在的进程组（等于其 pid）。为 nil 表示建组失败，只能单杀。
    private let processGroup: Int32?

    private let lock = NSLock()
    private var exitStatus: Int32?
    private var waiters: [CheckedContinuation<Int32, Never>] = []
    private var didRequestCancel = false
    /// SwiftPM 的 git 会主动创建新进程组；父进程退出后它会被 launchd 收养，
    /// 届时已无法再通过 PPID 找回，因此取消前必须先记住这些后代。
    private var descendantPIDs = Set<Int32>()
    private var descendantProcessGroups = Set<Int32>()

    init(pid: Int32, processGroup: Int32?, commandDescription: String) {
        self.processIdentifier = pid
        self.processGroup = processGroup
        self.commandDescription = commandDescription
    }

    var isRunning: Bool {
        lock.lock(); defer { lock.unlock() }
        return exitStatus == nil
    }

    /// 进程退出时由 reaper 调用：唤醒所有等待者。只会生效一次。
    fileprivate func complete(_ status: Int32) {
        lock.lock()
        guard exitStatus == nil else { lock.unlock(); return }
        exitStatus = status
        let pending = waiters
        waiters.removeAll()
        lock.unlock()
        for continuation in pending { continuation.resume(returning: status) }
    }

    /// 发送 SIGINT 给整个进程组。
    ///
    /// 对 xcodebuild 而言这一步才是真正让构建停下来的动作——见类型注释。
    func interrupt() {
        lock.lock()
        didRequestCancel = true
        let alive = exitStatus == nil
        lock.unlock()
        guard alive else { return }
        rememberDescendants()
        signalGroup(SIGINT)
    }

    /// SIGKILL 主进程组，以及取消前记录到的独立后代进程组。
    ///
    /// 这里刻意不要求组长仍然存活：父进程可能先退出，独立后代随后被
    /// launchd 收养。只要用户确实按过停止，就按取消前的快照完成清理。
    func forceTerminate() {
        lock.lock()
        let alive = exitStatus == nil
        let requested = didRequestCancel
        lock.unlock()
        guard alive || requested else { return }

        // 组长还活着时再补一次快照，覆盖 SIGINT 宽限期内新拉起的工具。
        if alive { rememberDescendants() }
        signalGroup(SIGKILL)

        lock.lock()
        let groups = descendantProcessGroups
        let pids = descendantPIDs
        lock.unlock()
        let ownGroup = getpgrp()
        for group in groups where group > 1 && group != ownGroup && group != processGroup {
            kill(-group, SIGKILL)
        }
        for pid in pids where pid > 1 {
            kill(pid, SIGKILL)
        }
    }

    private func rememberDescendants() {
        let pids = ProcessTree.descendants(of: processIdentifier)
        guard !pids.isEmpty else { return }
        let ownGroup = getpgrp()
        var groups = Set<Int32>()
        for pid in pids {
            let group = getpgid(pid)
            if group > 1, group != ownGroup, group != processGroup {
                groups.insert(group)
            }
        }
        lock.lock()
        descendantPIDs.formUnion(pids)
        descendantProcessGroups.formUnion(groups)
        lock.unlock()
    }

    private func signalGroup(_ signal: Int32) {
        if let processGroup, processGroup > 1 {
            kill(-processGroup, signal)
        } else if processIdentifier > 0 {
            kill(processIdentifier, signal)
        }
    }

    /// 先 SIGINT，`gracePeriod` 秒后再 SIGKILL 兜底。
    func cancel(gracePeriod: TimeInterval = 2) {
        interrupt()
        let deadline = DispatchTime.now() + gracePeriod
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: deadline) { [weak self] in
            self?.forceTerminate()
        }
    }

    /// 等待进程退出（不阻塞调用线程）。
    func waitUntilExit() async -> Int32 {
        await withCheckedContinuation { continuation in
            lock.lock()
            if let exitStatus {
                lock.unlock()
                continuation.resume(returning: exitStatus)
            } else {
                waiters.append(continuation)
                lock.unlock()
            }
        }
    }
}

// MARK: - 执行器

/// 所有命令行调用的唯一出口。
///
/// 三个必须处理的工程细节：
/// 1. stdout/stderr 管道若不及时读取，会在缓冲区满时死锁——因此一律用
///    `readabilityHandler` 异步消费，绝不使用 `readDataToEndOfFile`。
/// 2. 子进程必须自成进程组，取消时才能把信号发给整棵进程树。这里不用
///    `Foundation.Process`：它只能在 `run()` 之后由父进程补一次 `setpgid`，
///    而那时子进程往往已经 exec 完毕，调用会以 EACCES 失败，于是所有派生的
///    工具都杀不掉。`posix_spawn` 的 `POSIX_SPAWN_SETPGROUP` 是在 fork 与
///    exec 之间原子生效的，没有这个竞态。
/// 3. `POSIX_SPAWN_CLOEXEC_DEFAULT` 保证除了显式重定向的三个 fd 之外，
///    本进程打开的任何文件都不会泄漏进子进程。
enum ProcessRunner {

    /// 一次性执行，适用于 `-list` / `list devices` 等快速查询。
    static func run(
        _ executable: String,
        _ arguments: [String],
        cwd: URL? = nil,
        environment: [String: String]? = nil,
        timeout: TimeInterval = 60
    ) async throws -> ProcessResult {

        let collector = OutputCollector()
        let handle = try stream(
            executable,
            arguments,
            cwd: cwd,
            environment: environment,
            onLine: { line, kind in collector.append(line, kind) },
            onExit: { _ in }
        )

        // 用显式标记而不是「事后比较耗时」来判断超时：进程恰好在超时边界
        // 附近自然退出时，比较耗时会把正常结果误报成超时。
        let didTimeOut = AtomicFlag()
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            guard !Task.isCancelled else { return }
            didTimeOut.set()
            handle.cancel(gracePeriod: 1)
        }
        defer { timeoutTask.cancel() }

        let code = await withTaskCancellationHandler {
            await handle.waitUntilExit()
        } onCancel: {
            handle.cancel(gracePeriod: 1)
        }

        if didTimeOut.value {
            throw ProcessRunnerError.timedOut(command: handle.commandDescription, seconds: timeout)
        }
        try Task.checkCancellation()
        // 给 readabilityHandler 一个消费残余数据的机会
        try? await Task.sleep(nanoseconds: 30_000_000)

        return ProcessResult(exitCode: code, stdout: collector.stdout, stderr: collector.stderr)
    }

    /// 一次性执行并要求退出码为 0，否则抛错。
    @discardableResult
    static func runChecked(
        _ executable: String,
        _ arguments: [String],
        cwd: URL? = nil,
        environment: [String: String]? = nil,
        timeout: TimeInterval = 60
    ) async throws -> ProcessResult {
        let result = try await run(executable, arguments, cwd: cwd, environment: environment, timeout: timeout)
        guard result.isSuccess else {
            throw ProcessRunnerError.nonZeroExit(
                command: ([executable] + arguments).joined(separator: " "),
                code: result.exitCode,
                output: result.combinedTrimmed
            )
        }
        return result
    }

    /// 流式执行，适用于 build / launch --console 等长任务。返回句柄以支持取消。
    @discardableResult
    static func stream(
        _ executable: String,
        _ arguments: [String],
        cwd: URL? = nil,
        environment: [String: String]? = nil,
        onLine: @escaping @Sendable (String, StreamKind) -> Void,
        onExit: @escaping @Sendable (Int32) -> Void
    ) throws -> RunningProcess {

        let command = ([executable] + arguments).joined(separator: " ")

        var env = ProcessInfo.processInfo.environment
        // 让 xcodebuild 输出不带 ANSI 颜色控制符，便于正则解析
        env["NSUnbufferedIO"] = "YES"
        if let environment {
            for (key, value) in environment { env[key] = value }
        }

        var outPipe: [Int32] = [-1, -1]
        var errPipe: [Int32] = [-1, -1]
        guard pipe(&outPipe) == 0 else {
            throw ProcessRunnerError.launchFailed(command: command, reason: String(cString: strerror(errno)))
        }
        guard pipe(&errPipe) == 0 else {
            close(outPipe[0]); close(outPipe[1])
            throw ProcessRunnerError.launchFailed(command: command, reason: String(cString: strerror(errno)))
        }

        var fileActions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&fileActions)
        defer { posix_spawn_file_actions_destroy(&fileActions) }
        posix_spawn_file_actions_addopen(&fileActions, 0, "/dev/null", O_RDONLY, 0)
        posix_spawn_file_actions_adddup2(&fileActions, outPipe[1], 1)
        posix_spawn_file_actions_adddup2(&fileActions, errPipe[1], 2)
        if let cwd {
            posix_spawn_file_actions_addchdir(&fileActions, cwd.path)
        }

        var attributes: posix_spawnattr_t?
        posix_spawnattr_init(&attributes)
        defer { posix_spawnattr_destroy(&attributes) }
        // setpgroup(0) = 子进程成为自己进程组的组长，pgid 等于其 pid
        posix_spawnattr_setpgroup(&attributes, 0)
        posix_spawnattr_setflags(
            &attributes,
            Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_CLOEXEC_DEFAULT)
        )

        var argv: [UnsafeMutablePointer<CChar>?] = ([executable] + arguments).map { strdup($0) }
        argv.append(nil)
        var envp: [UnsafeMutablePointer<CChar>?] = env.map { strdup("\($0.key)=\($0.value)") }
        envp.append(nil)
        defer {
            for pointer in argv where pointer != nil { free(pointer) }
            for pointer in envp where pointer != nil { free(pointer) }
        }

        var pid: pid_t = 0
        let spawnResult = posix_spawn(&pid, executable, &fileActions, &attributes, argv, envp)

        // 写端必须由父进程关掉，否则读端永远等不到 EOF
        close(outPipe[1])
        close(errPipe[1])

        guard spawnResult == 0, pid > 0 else {
            close(outPipe[0])
            close(errPipe[0])
            throw ProcessRunnerError.launchFailed(
                command: command,
                reason: String(cString: strerror(spawnResult))
            )
        }

        let handle = RunningProcess(pid: pid, processGroup: pid, commandDescription: command)

        let stdoutBuffer = LineBuffer { line in onLine(line, .stdout) }
        let stderrBuffer = LineBuffer { line in onLine(line, .stderr) }
        let stdoutHandle = FileHandle(fileDescriptor: outPipe[0], closeOnDealloc: true)
        let stderrHandle = FileHandle(fileDescriptor: errPipe[0], closeOnDealloc: true)

        stdoutHandle.readabilityHandler = { fh in
            let data = fh.availableData
            if data.isEmpty {
                fh.readabilityHandler = nil
                stdoutBuffer.flush()
            } else {
                stdoutBuffer.consume(data)
            }
        }
        stderrHandle.readabilityHandler = { fh in
            let data = fh.availableData
            if data.isEmpty {
                fh.readabilityHandler = nil
                stderrBuffer.flush()
            } else {
                stderrBuffer.consume(data)
            }
        }

        // 用 DispatchSource 收尸，避免占用线程阻塞在 waitpid 上
        let source = DispatchSource.makeProcessSource(
            identifier: pid,
            eventMask: .exit,
            queue: reapQueue
        )
        source.setEventHandler {
            var raw: Int32 = 0
            waitpid(pid, &raw, 0)
            source.cancel()

            // 先把管道里的残余读干净，再通知等待者，保证错误行不丢
            stdoutHandle.readabilityHandler = nil
            stderrHandle.readabilityHandler = nil
            if let rest = try? stdoutHandle.readToEnd(), !rest.isEmpty { stdoutBuffer.consume(rest) }
            if let rest = try? stderrHandle.readToEnd(), !rest.isEmpty { stderrBuffer.consume(rest) }
            stdoutBuffer.flush()
            stderrBuffer.flush()
            try? stdoutHandle.close()
            try? stderrHandle.close()

            let status = exitStatus(fromWaitpid: raw)
            handle.complete(status)
            onExit(status)
        }
        source.resume()

        return handle
    }

    private static let reapQueue = DispatchQueue(label: "com.xcodecontrol.process-reap")

    /// 把 waitpid 的原始状态字解码为退出码。
    /// 被信号打断时返回 128+signal，与 shell 的约定一致（SIGINT → 130、SIGKILL → 137）。
    private static func exitStatus(fromWaitpid raw: Int32) -> Int32 {
        if raw & 0x7F == 0 {
            return (raw >> 8) & 0xFF
        }
        return 128 + (raw & 0x7F)
    }
}

// MARK: - 进程树

/// `xcodebuild` 的部分后代（尤其 SwiftPM 的 git）会脱离父进程组。
/// libproc 能在它们被父进程退出、PPID 改成 1 之前取得完整后代列表。
private enum ProcessTree {
    static func descendants(of root: Int32) -> Set<Int32> {
        guard root > 1 else { return [] }
        var result = Set<Int32>()
        var queue = [root]
        while let parent = queue.popLast() {
            for child in directChildren(of: parent) where result.insert(child).inserted {
                queue.append(child)
            }
        }
        return result
    }

    private static func directChildren(of parent: Int32) -> [Int32] {
        var capacity = 16
        while capacity <= 4_096 {
            var pids = [pid_t](repeating: 0, count: capacity)
            let count = proc_listchildpids(
                parent,
                &pids,
                Int32(MemoryLayout<pid_t>.stride * pids.count)
            )
            guard count > 0 else { return [] }
            if count < capacity {
                return pids.prefix(Int(count)).filter { $0 > 1 }
            }
            capacity *= 2
        }
        return []
    }
}

// MARK: - 辅助

/// 跨线程的一次性标记。
private final class AtomicFlag: @unchecked Sendable {
    private var flag = false
    private let lock = NSLock()

    func set() {
        lock.lock(); flag = true; lock.unlock()
    }

    var value: Bool {
        lock.lock(); defer { lock.unlock() }
        return flag
    }
}

/// 把字节流按 `\n` 切成行，跨 chunk 保留半行。
private final class LineBuffer: @unchecked Sendable {
    private var pending = Data()
    private let lock = NSLock()
    private let emit: @Sendable (String) -> Void

    init(emit: @escaping @Sendable (String) -> Void) {
        self.emit = emit
    }

    func consume(_ data: Data) {
        var lines: [String] = []
        lock.lock()
        pending.append(data)
        while let index = pending.firstIndex(of: 0x0A) {
            let lineData = pending[pending.startIndex..<index]
            pending.removeSubrange(pending.startIndex...index)
            if let line = String(data: lineData, encoding: .utf8) {
                lines.append(line.replacingOccurrences(of: "\r", with: ""))
            }
        }
        // 单行超过 1MB 视为异常输出，直接切断防止内存膨胀
        if pending.count > 1_000_000 {
            if let line = String(data: pending, encoding: .utf8) { lines.append(line) }
            pending.removeAll()
        }
        lock.unlock()
        for line in lines { emit(line) }
    }

    func flush() {
        lock.lock()
        let rest = pending
        pending.removeAll()
        lock.unlock()
        guard !rest.isEmpty, let line = String(data: rest, encoding: .utf8) else { return }
        emit(line.replacingOccurrences(of: "\r", with: ""))
    }
}

/// 线程安全地收集完整输出。
private final class OutputCollector: @unchecked Sendable {
    private var out: [String] = []
    private var err: [String] = []
    private let lock = NSLock()

    func append(_ line: String, _ kind: StreamKind) {
        lock.lock()
        switch kind {
        case .stdout: out.append(line)
        case .stderr: err.append(line)
        }
        lock.unlock()
    }

    var stdout: String {
        lock.lock(); defer { lock.unlock() }
        return out.joined(separator: "\n")
    }

    var stderr: String {
        lock.lock(); defer { lock.unlock() }
        return err.joined(separator: "\n")
    }
}
