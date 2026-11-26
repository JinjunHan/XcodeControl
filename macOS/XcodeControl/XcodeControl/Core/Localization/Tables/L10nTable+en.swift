//
//  L10nTable+en.swift
//  XcodeControl
//

/// 各语言译表的命名空间。key 是简体中文原文（源语言不建表）。
///
/// 英语表是基准：`Localization.missingKeys()` 以它的 key 集合比对其余语言，
/// 因此新增文案时先补这一份。
enum L10nTable {}

extension L10nTable {

    static let en: [String: String] = [
        // MARK: 主界面三元素
        "运行": "Run",
        "停止": "Stop",
        "选择设备": "Select Device",
        "清理后构建": "Clean Build",
        "模块缓存缺失，正在清理并重试": "Module cache missing. Cleaning and retrying…",
        "运行（长按可清理后构建）": "Run (hold to clean first)",
        "重新运行（长按可清理后构建）": "Run Again (hold to clean first)",
        "取消构建": "Cancel Build",
        "停止运行": "Stop Running",
        "正在构建…": "Building…",

        // MARK: 运行状态
        "Building": "Building",
        "Installing": "Installing",
        "Launching": "Launching",
        "Running": "Running",
        "Failed": "Failed",
        "准备": "Preparing",
        "解析依赖": "Resolving Dependencies",
        "编译 Swift": "Compiling Swift",
        "编译 C/ObjC": "Compiling C/ObjC",
        "编译资源": "Compiling Assets",
        "编译界面": "Compiling Interface",
        "处理 Info.plist": "Processing Info.plist",
        "运行脚本": "Running Script",
        "链接": "Linking",
        "签名": "Signing",
        "收尾": "Finishing",
        "校验": "Validating",

        // MARK: 设备
        "模拟器": "Simulators",
        "已连接设备": "Connected Devices",
        "本机": "This Mac",
        "我的 Mac": "My Mac",
        "已启动": "Booted",
        "已连接": "Connected",
        "未连接": "Disconnected",
        "搜索设备": "Search devices",
        "刷新设备列表": "Refresh device list",
        "没有匹配的设备": "No matching devices",
        "没有可用设备": "No devices available",
        "未命名设备": "Unnamed Device",

        // MARK: 项目
        "项目": "Project",
        "项目列表": "Projects",
        "未选择项目": "No project selected",
        "尚未选择项目": "No project selected yet",
        "添加项目…": "Add Project…",
        "管理项目…": "Manage Projects…",
        "选择项目…": "Choose Project…",
        "在 Xcode 中打开": "Open in Xcode",
        "从列表移除": "Remove from List",
        "从列表中删除": "Remove from List",
        "路径已失效": "Path unavailable",
        "路径失效": "Path unavailable",
        "%@（路径已失效）": "%@ (path unavailable)",
        "设为当前项目": "Set as Current Project",
        "当前": "Current",
        "选择或拖入 Xcode 项目": "Choose or drop an Xcode project",
        "拖入 .xcodeproj / .xcworkspace，或项目文件夹":
            "Drop a .xcodeproj / .xcworkspace, or a project folder",
        "正在解析…": "Resolving…",
        "未解析到 scheme": "No scheme found",
        "解析失败，见悬浮窗": "Resolve failed — see the panel",

        // MARK: Git
        "当前项目不在 Git 仓库中": "The current project is not in a Git repository",
        "无法读取当前 Git 分支": "Unable to read the current Git branch",
        "分支已不存在，请刷新列表后重试": "The branch no longer exists. Refresh the list and try again",
        "当前修改会被覆盖，请先提交或暂存后再切换分支":
            "Your current changes would be overwritten. Commit or stash them before switching branches",
        "仓库有未解决的冲突，请先处理后再切换分支":
            "The repository has unresolved conflicts. Resolve them before switching branches",
        "该分支正在另一个 Git worktree 中使用": "This branch is in use by another Git worktree",
        "切换分支失败：%@": "Failed to switch branch: %@",
        "切换 Git 分支": "Switch Git Branch",
        "本地分支": "Local Branches",
        "正在读取分支…": "Loading branches…",
        "没有本地分支": "No local branches",
        "刷新分支列表": "Refresh branch list",
        "同步 Worktree 项目": "Sync Worktree Projects",
        "Git worktree 路径已失效，请先在终端清理该 worktree":
            "The Git worktree path is invalid. Clean up that worktree in Terminal first",
        "worktree": "worktree",
        "Git 操作详情：%@": "Git operation details: %@",
        "构建进行中，停止后可切换分支":
            "A build is in progress. Stop it before switching branches",

        // MARK: 日志
        "日志": "Log",
        "收起日志": "Collapse Log",
        "拷贝完整日志": "Copy Full Log",
        "拷贝错误信息": "Copy Error",
        "拷贝命令": "Copy Command",
        "查看完整日志": "View Full Log",
        "过滤": "Filter",
        "自动滚动：开": "Auto-scroll: On",
        "自动滚动：关": "Auto-scroll: Off",

        // MARK: 通用动作
        "设置": "Settings",
        "设置…": "Settings…",
        "关闭": "Close",
        "取消": "Cancel",
        "完成": "Done",
        "清除": "Clear",
        "清理": "Clean",
        "清理…": "Clean…",
        "清空": "Clear All",
        "添加": "Add",
        "扫描": "Scan",
        "扫描文件夹…": "Scan Folder…",
        "选择": "Choose",
        "好的": "OK",
        "启用": "Enable",
        "打开系统设置": "Open System Settings",
        "在 Finder 中显示": "Show in Finder",
        "显示悬浮窗": "Show Panel",
        "隐藏悬浮窗": "Hide Panel",
        "退出 XcodeControl": "Quit XcodeControl",
        "其他…": "Other…",
        "自定义": "Custom",
        "自定义…": "Custom…",
        "默认": "Default",
        "未知": "Unknown",
        "秒": "s",
        "空格": "Space",
        "语言": "Language",
        "界面语言": "Interface Language",
        "跟随系统": "Follow System",

        // MARK: 设置页
        "通用": "General",
        "构建": "Build",
        "行为": "Behavior",
        "位置": "Locations",
        "关于": "About",
        "启动": "Startup",
        "浮窗": "Panel",
        "设备": "Devices",
        "偏好设置": "Preferences",
        "开机自启动": "Launch at Login",
        "启动时显示浮窗": "Show panel at launch",
        "启动时打开设置": "Open Settings at launch",
        "显示 Git 分支": "Show Git branch",
        "失焦时降低不透明度": "Dim when inactive",
        "不透明度": "Opacity",
        "重置窗口位置": "Reset Window Position",
        "缓冲行数": "Buffer lines",
        "刷新间隔": "Refresh interval",
        "开机自启动由系统「登录项」管理；首次开启可能需要你在系统设置里确认。":
            "Launch at login is managed by the system Login Items; the first time you enable it you may need to confirm in System Settings.",
        "需要在系统设置中允许登录项。": "You need to allow the login item in System Settings.",
        "已申请开机自启，请在系统设置 › 通用 › 登录项中允许。":
            "Launch at login was requested. Allow it in System Settings › General › Login Items.",
        "超出后丢弃最旧的行。": "Oldest lines are dropped beyond this limit.",
        "构建期间自动暂停轮询。低于 2 秒无效。":
            "Polling pauses during builds. Values under 2 seconds have no effect.",

        // MARK: 设置页 · 构建
        "附着控制台输出": "Attach console output",
        "附着后可在日志面板看到 App 的实时输出，代价是拿不到进程 PID。关闭则以分离方式启动。":
            "Attaching shows the app's live output in the log pane, at the cost of not getting the process PID. Turn it off to launch detached.",
        "失败处理": "On Failure",
        "构建失败时自动展开日志": "Expand log when a build fails",
        "失败后日志面板自动弹出，方便立刻看到错误。":
            "The log pane opens automatically so you see the error right away.",

        // MARK: 设置页 · 行为
        "构建成功时": "On Success",
        "构建失败时": "On Failure",
        "发送通知": "Send notification",
        "播放声音": "Play sound",
        "浮窗隐藏时同样生效。": "Applies even when the panel is hidden.",
        "全局快捷键": "Global Shortcuts",
        "已被占用": "Already in use",
        "需要通知权限": "Notification Permission Needed",
        "系统拒绝了通知权限。请在系统设置中为 XcodeControl 开启通知，然后再试。":
            "The system denied notification permission. Enable notifications for XcodeControl in System Settings, then try again.",
        "构建成功": "Build Succeeded",
        "构建失败": "Build Failed",

        // MARK: 设置页 · 位置
        "命令行工具": "Command Line Tools",
        "Derived Data 位置": "Derived Data Location",
        "构建设置缓存": "Build Settings Cache",
        "系统默认（xcode-select）": "System Default (xcode-select)",
        "选择 Xcode.app": "Choose Xcode.app",
        "选择 Derived Data 根目录": "Choose Derived Data Root",
        "选择自定义目录": "Choose Custom Directory",
        "更改仅影响本应用的 DEVELOPER_DIR，不会改动系统的 xcode-select。":
            "This only changes DEVELOPER_DIR for this app; the system xcode-select is left alone.",
        "清理 Derived Data？": "Clean Derived Data?",
        "清除构建设置缓存？": "Clear Build Settings Cache?",
        "回收": "Reap",
        "回收…": "Reap…",
        "%d 天未构建": "not built for %d days",
        "全部清除…": "Delete All…",
        "清除全部 Derived Data？": "Delete All Derived Data?",
        "Xcode 自己从不回收 Derived Data：工程移动或删除后，旧缓存会一直留在磁盘上。":
            "Xcode never reaps Derived Data on its own: after a project is moved or deleted, its cache stays on disk forever.",
        "自动回收": "Automatic Reaping",
        "回收已删除工程的缓存": "Reap caches of deleted projects",
        "回收长期未构建的缓存": "Reap caches not built for a long time",
        "这一项删的是仍在使用的工程的缓存，代价是下次全量重编。构建成功后在后台执行，每天最多一次。":
            "This removes caches of projects that are still in use, at the cost of a full rebuild next time. Runs in the background after a successful build, at most once per day.",
        "超过 %d 天未构建": "Not built for over %d days",
        "依据缓存里记录的工程路径判定；路径已不存在即回收。判不出归属的目录会跳过。":
            "Judged by the project path recorded in each cache; if the path no longer exists, it is reaped. Directories whose owner cannot be determined are skipped.",
        "自定义目录由本应用管理，可精确判定归属；不属于任何已托管工程的目录即回收。":
            "This custom directory is managed by this app, so ownership is exact; any directory not belonging to a managed project is reaped.",
        "没有可回收的 Derived Data": "No Derived Data to Reap",
        "所有缓存都属于仍在使用的工程。": "All caches belong to projects still in use.",
        "回收 %d 份 Derived Data？": "Reap %d Derived Data caches?",
        "共可释放 %@。此操作不可撤销。": "%@ can be freed. This cannot be undone.",
        "已回收 %d 份无用的 Derived Data，释放 %@":
            "Reaped %d useless Derived Data caches, freeing %@",
        "工程已不存在": "Project no longer exists",
        "…另有 %d 份": "…and %d more",
        "启动后获取": "Read at launch",
        "路径": "Path",
        "版本": "Version",
        "检查更新…": "Check for Updates…",
        "反馈问题": "Report an Issue",
        "请通过 GitHub Issues 反馈问题，或在代码仓库提 PR。":
            "Report issues through GitHub Issues, or open a PR on the repository.",

        // MARK: 设置页 · 项目
        "清空项目": "Clear Projects",
        "清空全部项目？": "Clear All Projects?",
        "列表中的 %d 个项目都会移除，当前项目也会取消。":
            "All %d projects will be removed and the current project deselected.",
        "还没有项目。拖入工程文件/文件夹，或用下方按钮添加。":
            "No projects yet. Drop a project file or folder, or add one with the button below.",
        "拖拽行可调整顺序；也可拖入工程文件或文件夹添加。":
            "Drag rows to reorder; you can also drop project files or folders to add them.",
        "支持拖入 .xcodeproj / .xcworkspace，或包含它们的文件夹。":
            "Accepts .xcodeproj / .xcworkspace files, or folders containing them.",
        "选择 .xcodeproj / .xcworkspace，或包含它们的目录":
            "Choose a .xcodeproj / .xcworkspace, or a directory containing one",
        "选择 .xcodeproj 或 .xcworkspace": "Choose a .xcodeproj or .xcworkspace",
        "选择要扫描的根目录。同目录下若同时有 workspace 与 xcodeproj，只导入 workspace。":
            "Choose a root directory to scan. When a folder holds both a workspace and an xcodeproj, only the workspace is imported.",
        "正在扫描…": "Scanning…",
        "已添加 %d 个项目。": "Added %d projects.",
        "已通过拖放加入 %d 个项目。": "Added %d projects by drop.",
        "扫描完成：新增 %d 个，已存在 %d 个。": "Scan complete: %d added, %d already present.",
        "Worktree 同步完成：新增项目 %d 个，已存在 %d 个，未找到工程的 worktree %d 个。":
            "Worktree sync complete: %d projects added, %d already present, %d worktrees had no project.",
        "没有新项目加入（可能已在列表中）。":
            "No new projects added (they may already be in the list).",
        "没有新项目加入（可能已在列表中或无法识别）。":
            "No new projects added (they may already be in the list, or weren't recognized).",
        "未在该目录下发现可导入的工程。": "No importable projects found in that directory.",
        "未识别到 .xcodeproj / .xcworkspace": "No .xcodeproj / .xcworkspace recognized",

        // MARK: 环境错误
        "正在检查 Xcode 环境…": "Checking the Xcode environment…",
        "环境不可用": "Environment unavailable",
        "环境检查失败": "Environment check failed",
        "未能确定 Xcode 位置": "Couldn't determine the Xcode location",
        "当前选中的是 Command Line Tools，不是完整的 Xcode":
            "The Command Line Tools are selected, not a full Xcode",
        "请选择要使用的 Xcode": "Choose which Xcode to use",
        "未找到完整的 Xcode": "No full Xcode installation was found",
        "前往设置": "Open Settings",
        "安装 Xcode": "Install Xcode",
        "xcodebuild 不可用": "xcodebuild is unavailable",
        "Xcode %@ 尚未验证，若行为异常请反馈":
            "Xcode %@ hasn't been verified — please report anything that misbehaves",

        // MARK: 运行前置校验
        "还没有选择项目": "No project selected yet",
        "还没有选择 scheme": "No scheme selected yet",
        "还没有选择运行目标": "No run destination selected yet",
        "已取消": "Cancelled",
        "App 启动后立即退出": "The app quit immediately after launching",
        "App 已退出（退出码 %d）": "The app exited (code %d)",

        // MARK: 工具链错误
        "无法解析 xcodebuild -list 的输出": "Couldn't parse the output of xcodebuild -list",
        "xcodebuild -list 输出中既没有 project 也没有 workspace":
            "The xcodebuild -list output contains neither a project nor a workspace",
        "无法解析 -showBuildSettings 的输出": "Couldn't parse the output of -showBuildSettings",
        "无法解析 simctl list devices 的输出": "Couldn't parse the output of simctl list devices",
        "无法解析 devicectl list devices 的输出": "Couldn't parse the output of devicectl list devices",
        "读取项目信息失败": "Failed to read project information",
        "读取构建设置失败": "Failed to read build settings",
        "读取模拟器列表失败": "Failed to read the simulator list",
        "读取真机列表失败": "Failed to read the device list",
        "该项目没有可用的 scheme（只有勾选 Shared 的 scheme 才会出现在列表中）":
            "This project has no usable scheme (only schemes marked Shared appear in the list)",
        "构建设置中没有 PRODUCT_BUNDLE_IDENTIFIER，该 scheme 可能不是可运行的 App target":
            "Build settings have no PRODUCT_BUNDLE_IDENTIFIER — this scheme may not be a runnable app target",
        "构建设置中缺少 BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME":
            "Build settings are missing BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME",
        "模拟器启动超时": "Timed out waiting for the simulator to boot",
        "启动模拟器失败：%@": "Failed to boot the simulator: %@",
        "安装到模拟器失败：%@": "Failed to install to the simulator: %@",
        "在模拟器上启动 App 失败：%@": "Failed to launch the app on the simulator: %@",
        "安装到设备失败：%@": "Failed to install to the device: %@",
        "在设备上启动 App 失败：%@": "Failed to launch the app on the device: %@",
        "无法执行 %@：%@": "Couldn't run %@: %@",
        "%@ 执行超时（%ds）": "%@ timed out (%ds)",
        "%@ 退出码 %d": "%@ exited with code %d",
        "未知错误": "Unknown error",

        // MARK: 工程与书签
        "%@ 不是 Xcode 工程": "%@ isn't an Xcode project",
        "%@ 中找不到 .xcodeproj 或 .xcworkspace": "No .xcodeproj or .xcworkspace found in %@",
        "书签已失效，请重新选择项目": "The bookmark is stale — choose the project again",
        "无法为 %@ 创建书签": "Couldn't create a bookmark for %@",
        "找不到 %@": "Couldn't find %@",

        // MARK: ErrorTranslator（可执行的下一步）
        "设备已锁屏，请解锁后重试": "The device is locked — unlock it and try again",
        "安装被拒绝：签名与设备不匹配，检查 provisioning profile 是否包含该设备":
            "Install refused: the signature doesn't match the device. Check that the provisioning profile includes this device",
        "provisioning profile 未包含任何设备，请在开发者后台添加该设备":
            "The provisioning profile contains no devices — add this device in the developer portal",
        "缺少可用的 provisioning profile，请在 Xcode 中打开 Signing & Capabilities 配置自动签名":
            "No usable provisioning profile — open Signing & Capabilities in Xcode and enable automatic signing",
        "签名失败：真机构建必须配置有效的签名证书与描述文件":
            "Signing failed: device builds need a valid signing certificate and provisioning profile",
        "找不到签名证书，请在 Xcode 的账户设置中登录并下载证书":
            "No signing certificate found — sign in under Xcode's account settings and download your certificates",
        "设备的开发者磁盘映像未挂载，通常重新插拔或重启设备可恢复":
            "The device's developer disk image isn't mounted — reconnecting or restarting the device usually fixes it",
        "设备未开启「开发者模式」，请在 设置 › 隐私与安全性 › 开发者模式 中打开":
            "Developer Mode is off on the device — turn it on under Settings › Privacy & Security › Developer Mode",
        "设备未连接或未信任本机，请检查连接后重试":
            "The device isn't connected or doesn't trust this Mac — check the connection and try again",
        "该模拟器的数据已丢失，请在 Xcode › Devices and Simulators 中删除后重建":
            "This simulator's data is gone — delete and recreate it in Xcode › Devices and Simulators",
        "模拟器无法启动，尝试在 Simulator 中执行 Device › Erase All Content and Settings":
            "The simulator won't boot — try Device › Erase All Content and Settings in Simulator",
        "App 尚未安装到该设备，请重新运行一次":
            "The app isn't installed on that device yet — run it once more",
        "该 scheme 未配置当前 action，请检查 scheme 的 Build/Run 设置":
            "This scheme isn't configured for the current action — check its Build/Run settings",
        "工程中找不到该 scheme，可能已被重命名或未勾选 Shared":
            "The scheme isn't in the project — it may have been renamed or isn't marked Shared",
        "找不到匹配的运行目标，设备可能已断开或模拟器已被删除":
            "No matching destination — the device may be disconnected or the simulator deleted",
        "工程路径无效，文件可能已被移动或删除":
            "The project path is invalid — the files may have been moved or deleted",
        "找不到构建产物，请重新构建": "Build product not found — build again",
    ]
}
