//
//  L10nTable+de.swift
//  XcodeControl
//

extension L10nTable {

    static let de: [String: String] = [
        // MARK: 主界面三元素
        "运行": "Ausführen",
        "停止": "Stopp",
        "选择设备": "Gerät wählen",
        "清理后构建": "Bereinigen und bauen",
        "模块缓存缺失，正在清理并重试": "Modulcache fehlt. Neuer Build nach Bereinigung…",
        "运行（长按可清理后构建）": "Ausführen (gedrückt halten: vorher bereinigen)",
        "重新运行（长按可清理后构建）": "Erneut ausführen (gedrückt halten: vorher bereinigen)",
        "取消构建": "Build abbrechen",
        "停止运行": "Ausführung stoppen",
        "正在构建…": "Build läuft…",

        // MARK: 运行状态
        "Building": "Build läuft",
        "Installing": "Installation läuft",
        "Launching": "Startet",
        "Running": "Läuft",
        "Failed": "Fehlgeschlagen",
        "准备": "Vorbereiten",
        "解析依赖": "Abhängigkeiten auflösen",
        "编译 Swift": "Swift kompilieren",
        "编译 C/ObjC": "C/ObjC kompilieren",
        "编译资源": "Assets kompilieren",
        "编译界面": "Interface kompilieren",
        "处理 Info.plist": "Info.plist verarbeiten",
        "运行脚本": "Skript ausführen",
        "链接": "Linken",
        "签名": "Signieren",
        "收尾": "Abschließen",
        "校验": "Validieren",

        // MARK: 设备
        "模拟器": "Simulatoren",
        "已连接设备": "Verbundene Geräte",
        "本机": "Dieser Mac",
        "我的 Mac": "Mein Mac",
        "已启动": "Gestartet",
        "已连接": "Verbunden",
        "未连接": "Nicht verbunden",
        "搜索设备": "Geräte suchen",
        "刷新设备列表": "Geräteliste aktualisieren",
        "没有匹配的设备": "Keine passenden Geräte",
        "没有可用设备": "Keine Geräte verfügbar",
        "未命名设备": "Unbenanntes Gerät",

        // MARK: 项目
        "项目": "Projekt",
        "项目列表": "Projekte",
        "未选择项目": "Kein Projekt ausgewählt",
        "尚未选择项目": "Noch kein Projekt ausgewählt",
        "添加项目…": "Projekt hinzufügen…",
        "管理项目…": "Projekte verwalten…",
        "选择项目…": "Projekt wählen…",
        "在 Xcode 中打开": "In Xcode öffnen",
        "从列表移除": "Aus Liste entfernen",
        "从列表中删除": "Aus der Liste entfernen",
        "路径已失效": "Pfad nicht verfügbar",
        "路径失效": "Pfad nicht verfügbar",
        "%@（路径已失效）": "%@ (Pfad nicht verfügbar)",
        "设为当前项目": "Als aktuelles Projekt festlegen",
        "当前": "Aktuell",
        "选择或拖入 Xcode 项目": "Xcode-Projekt wählen oder ablegen",
        "拖入 .xcodeproj / .xcworkspace，或项目文件夹":
            ".xcodeproj / .xcworkspace oder einen Projektordner ablegen",
        "正在解析…": "Wird analysiert…",
        "未解析到 scheme": "Kein scheme gefunden",
        "解析失败，见悬浮窗": "Analyse fehlgeschlagen – siehe Panel",

        // MARK: Git
        "当前项目不在 Git 仓库中": "Das aktuelle Projekt befindet sich nicht in einem Git-Repository",
        "无法读取当前 Git 分支": "Der aktuelle Git-Branch konnte nicht gelesen werden",
        "分支已不存在，请刷新列表后重试": "Der Branch existiert nicht mehr. Aktualisiere die Liste und versuche es erneut",
        "当前修改会被覆盖，请先提交或暂存后再切换分支":
            "Die aktuellen Änderungen würden überschrieben. Committe oder stashe sie vor dem Branchwechsel",
        "仓库有未解决的冲突，请先处理后再切换分支":
            "Im Repository gibt es ungelöste Konflikte. Löse sie vor dem Branchwechsel",
        "该分支正在另一个 Git worktree 中使用": "Dieser Branch wird in einem anderen Git-Worktree verwendet",
        "切换分支失败：%@": "Branchwechsel fehlgeschlagen: %@",
        "切换 Git 分支": "Git-Branch wechseln",
        "本地分支": "Lokale Branches",
        "正在读取分支…": "Branches werden geladen…",
        "没有本地分支": "Keine lokalen Branches",
        "刷新分支列表": "Branchliste aktualisieren",
        "同步 Worktree 项目": "Worktree-Projekte synchronisieren",
        "Git worktree 路径已失效，请先在终端清理该 worktree":
            "Der Git-Worktree-Pfad ist ungültig. Bereinige zuerst den Worktree im Terminal",
        "worktree": "Worktree",
        "Git 操作详情：%@": "Details zum Git-Vorgang: %@",
        "构建进行中，停止后可切换分支":
            "Ein Build läuft. Stoppe ihn vor dem Branchwechsel",

        // MARK: 日志
        "日志": "Log",
        "收起日志": "Log einklappen",
        "拷贝完整日志": "Gesamtes Log kopieren",
        "拷贝错误信息": "Fehler kopieren",
        "拷贝命令": "Befehl kopieren",
        "查看完整日志": "Gesamtes Log ansehen",
        "过滤": "Filter",
        "自动滚动：开": "Auto-Scroll: Ein",
        "自动滚动：关": "Auto-Scroll: Aus",

        // MARK: 通用动作
        "设置": "Einstellungen",
        "设置…": "Einstellungen…",
        "关闭": "Schließen",
        "取消": "Abbrechen",
        "完成": "Fertig",
        "清除": "Löschen",
        "清理": "Bereinigen",
        "清理…": "Bereinigen…",
        "清空": "Alle löschen",
        "添加": "Hinzufügen",
        "扫描": "Scannen",
        "扫描文件夹…": "Ordner scannen…",
        "选择": "Auswählen",
        "好的": "OK",
        "启用": "Aktivieren",
        "打开系统设置": "Systemeinstellungen öffnen",
        "在 Finder 中显示": "Im Finder anzeigen",
        "显示悬浮窗": "Panel einblenden",
        "隐藏悬浮窗": "Panel ausblenden",
        "退出 XcodeControl": "XcodeControl beenden",
        "其他…": "Andere…",
        "自定义": "Eigene",
        "自定义…": "Eigene…",
        "默认": "Standard",
        "未知": "Unbekannt",
        "秒": "s",
        "空格": "Leertaste",
        "语言": "Sprache",
        "界面语言": "Sprache der Oberfläche",
        "跟随系统": "Wie System",

        // MARK: 设置页
        "通用": "Allgemein",
        "构建": "Build",
        "行为": "Verhalten",
        "位置": "Orte",
        "关于": "Über",
        "启动": "Start",
        "浮窗": "Panel",
        "设备": "Geräte",
        "偏好设置": "Voreinstellungen",
        "开机自启动": "Bei der Anmeldung öffnen",
        "启动时显示浮窗": "Panel beim Start anzeigen",
        "启动时打开设置": "Einstellungen beim Start öffnen",
        "显示 Git 分支": "Git-Branch anzeigen",
        "失焦时降低不透明度": "Deckkraft bei Inaktivität senken",
        "不透明度": "Deckkraft",
        "重置窗口位置": "Fensterposition zurücksetzen",
        "缓冲行数": "Pufferzeilen",
        "刷新间隔": "Aktualisierungsintervall",
        "开机自启动由系统「登录项」管理；首次开启可能需要你在系统设置里确认。":
            "Der Start bei der Anmeldung wird über die systemweiten Anmeldeobjekte verwaltet; beim ersten Aktivieren musst du das eventuell in den Systemeinstellungen bestätigen.",
        "需要在系统设置中允许登录项。":
            "Du musst das Anmeldeobjekt in den Systemeinstellungen erlauben.",
        "已申请开机自启，请在系统设置 › 通用 › 登录项中允许。":
            "Der Start bei der Anmeldung wurde angefordert. Erlaube ihn unter Systemeinstellungen › Allgemein › Anmeldeobjekte.",
        "超出后丢弃最旧的行。": "Jenseits dieser Grenze werden die ältesten Zeilen verworfen.",
        "构建期间自动暂停轮询。低于 2 秒无效。":
            "Während eines Builds pausiert das Abfragen. Werte unter 2 Sekunden haben keine Wirkung.",

        // MARK: 设置页 · 构建
        "附着控制台输出": "Konsolenausgabe anhängen",
        "附着后可在日志面板看到 App 的实时输出，代价是拿不到进程 PID。关闭则以分离方式启动。":
            "Angehängt siehst du die Live-Ausgabe der App im Log-Bereich, dafür bekommst du keine PID des Prozesses. Schalte es aus, um losgelöst zu starten.",
        "失败处理": "Bei Fehlschlag",
        "构建失败时自动展开日志": "Log bei fehlgeschlagenem Build ausklappen",
        "失败后日志面板自动弹出，方便立刻看到错误。":
            "Der Log-Bereich öffnet sich automatisch, damit du den Fehler sofort siehst.",

        // MARK: 设置页 · 行为
        "构建成功时": "Bei Erfolg",
        "构建失败时": "Bei Fehlschlag",
        "发送通知": "Mitteilung senden",
        "播放声音": "Ton abspielen",
        "浮窗隐藏时同样生效。": "Gilt auch, wenn das Panel ausgeblendet ist.",
        "全局快捷键": "Globale Tastaturkurzbefehle",
        "已被占用": "Bereits belegt",
        "需要通知权限": "Erlaubnis für Mitteilungen nötig",
        "系统拒绝了通知权限。请在系统设置中为 XcodeControl 开启通知，然后再试。":
            "Das System hat Mitteilungen verweigert. Aktiviere Mitteilungen für XcodeControl in den Systemeinstellungen und versuche es erneut.",
        "构建成功": "Build erfolgreich",
        "构建失败": "Build fehlgeschlagen",

        // MARK: 设置页 · 位置
        "命令行工具": "Command Line Tools",
        "Derived Data 位置": "Ort von Derived Data",
        "构建设置缓存": "Cache der Build-Einstellungen",
        "系统默认（xcode-select）": "Systemstandard (xcode-select)",
        "选择 Xcode.app": "Xcode.app auswählen",
        "选择 Derived Data 根目录": "Stammordner für Derived Data wählen",
        "选择自定义目录": "Eigenes Verzeichnis wählen",
        "更改仅影响本应用的 DEVELOPER_DIR，不会改动系统的 xcode-select。":
            "Die Änderung betrifft nur DEVELOPER_DIR dieser App; das systemweite xcode-select bleibt unberührt.",
        "清理 Derived Data？": "Derived Data bereinigen?",
        "清除构建设置缓存？": "Cache der Build-Einstellungen löschen?",
        "回收": "Aufräumen",
        "回收…": "Aufräumen…",
        "%d 天未构建": "seit %d Tagen nicht gebaut",
        "全部清除…": "Alle löschen…",
        "清除全部 Derived Data？": "Alle Derived Data löschen?",
        "Xcode 自己从不回收 Derived Data：工程移动或删除后，旧缓存会一直留在磁盘上。":
            "Xcode räumt Derived Data nie selbst auf: Nach dem Verschieben oder Löschen eines Projekts bleibt der alte Cache dauerhaft auf der Festplatte.",
        "自动回收": "Automatisches Aufräumen",
        "回收已删除工程的缓存": "Caches gelöschter Projekte aufräumen",
        "回收长期未构建的缓存": "Lange nicht gebaute Caches aufräumen",
        "这一项删的是仍在使用的工程的缓存，代价是下次全量重编。构建成功后在后台执行，每天最多一次。":
            "Hierbei werden Caches noch genutzter Projekte gelöscht – der Preis ist ein vollständiger Neubau beim nächsten Mal. Läuft nach einem erfolgreichen Build im Hintergrund, höchstens einmal täglich.",
        "超过 %d 天未构建": "Seit über %d Tagen nicht gebaut",
        "依据缓存里记录的工程路径判定；路径已不存在即回收。判不出归属的目录会跳过。":
            "Beurteilt anhand des im Cache vermerkten Projektpfads; existiert er nicht mehr, wird aufgeräumt. Verzeichnisse ohne bestimmbare Zugehörigkeit werden übersprungen.",
        "自定义目录由本应用管理，可精确判定归属；不属于任何已托管工程的目录即回收。":
            "Das eigene Verzeichnis wird von dieser App verwaltet, die Zugehörigkeit ist also exakt bestimmbar; Verzeichnisse ohne verwaltetes Projekt werden aufgeräumt.",
        "没有可回收的 Derived Data": "Keine Derived Data zum Aufräumen",
        "所有缓存都属于仍在使用的工程。": "Alle Caches gehören zu weiterhin genutzten Projekten.",
        "回收 %d 份 Derived Data？": "%d Derived-Data-Caches aufräumen?",
        "共可释放 %@。此操作不可撤销。": "Insgesamt %@ können freigegeben werden. Dies kann nicht rückgängig gemacht werden.",
        "已回收 %d 份无用的 Derived Data，释放 %@":
            "%d nutzlose Derived-Data-Caches aufgeräumt, %@ freigegeben",
        "工程已不存在": "Projekt existiert nicht mehr",
        "…另有 %d 份": "…und %d weitere",
        "启动后获取": "Wird beim Start gelesen",
        "路径": "Pfad",
        "版本": "Version",
        "检查更新…": "Nach Updates suchen…",
        "反馈问题": "Problem melden",
        "请通过 GitHub Issues 反馈问题，或在代码仓库提 PR。":
            "Melde Probleme über GitHub Issues oder öffne einen PR im Repository.",

        // MARK: 设置页 · 项目
        "清空项目": "Projekte löschen",
        "清空全部项目？": "Alle Projekte löschen?",
        "列表中的 %d 个项目都会移除，当前项目也会取消。":
            "Alle %d Projekte werden entfernt und das aktuelle Projekt wird abgewählt.",
        "还没有项目。拖入工程文件/文件夹，或用下方按钮添加。":
            "Noch keine Projekte. Lege eine Projektdatei oder einen Ordner ab, oder füge unten eines hinzu.",
        "拖拽行可调整顺序；也可拖入工程文件或文件夹添加。":
            "Ziehe Zeilen, um sie umzusortieren; du kannst auch Projektdateien oder Ordner ablegen.",
        "支持拖入 .xcodeproj / .xcworkspace，或包含它们的文件夹。":
            "Nimmt .xcodeproj / .xcworkspace an, oder Ordner, die sie enthalten.",
        "选择 .xcodeproj / .xcworkspace，或包含它们的目录":
            ".xcodeproj / .xcworkspace wählen, oder ein Verzeichnis, das sie enthält",
        "选择 .xcodeproj 或 .xcworkspace": ".xcodeproj oder .xcworkspace wählen",
        "选择要扫描的根目录。同目录下若同时有 workspace 与 xcodeproj，只导入 workspace。":
            "Wähle ein Stammverzeichnis zum Scannen. Enthält ein Ordner sowohl ein workspace als auch ein xcodeproj, wird nur das workspace importiert.",
        "正在扫描…": "Wird gescannt…",
        "已添加 %d 个项目。": "%d Projekte hinzugefügt.",
        "已通过拖放加入 %d 个项目。": "%d Projekte per Ablegen hinzugefügt.",
        "扫描完成：新增 %d 个，已存在 %d 个。":
            "Scan abgeschlossen: %d hinzugefügt, %d schon vorhanden.",
        "Worktree 同步完成：新增项目 %d 个，已存在 %d 个，未找到工程的 worktree %d 个。":
            "Worktree-Synchronisierung abgeschlossen: %d Projekte hinzugefügt, %d bereits vorhanden, in %d Worktrees kein Projekt gefunden.",
        "没有新项目加入（可能已在列表中）。":
            "Keine neuen Projekte hinzugefügt (sie sind vermutlich schon in der Liste).",
        "没有新项目加入（可能已在列表中或无法识别）。":
            "Keine neuen Projekte hinzugefügt (sie sind schon in der Liste oder wurden nicht erkannt).",
        "未在该目录下发现可导入的工程。":
            "In diesem Verzeichnis wurden keine importierbaren Projekte gefunden.",
        "未识别到 .xcodeproj / .xcworkspace": "Kein .xcodeproj / .xcworkspace erkannt",

        // MARK: 环境错误
        "正在检查 Xcode 环境…": "Xcode-Umgebung wird geprüft…",
        "环境不可用": "Umgebung nicht verfügbar",
        "环境检查失败": "Umgebungsprüfung fehlgeschlagen",
        "未能确定 Xcode 位置": "Ort von Xcode konnte nicht bestimmt werden",
        "当前选中的是 Command Line Tools，不是完整的 Xcode":
            "Ausgewählt sind die Command Line Tools, nicht ein vollständiges Xcode",
        "请选择要使用的 Xcode": "Wähle das zu verwendende Xcode",
        "未找到完整的 Xcode": "Es wurde keine vollständige Xcode-Installation gefunden",
        "前往设置": "Einstellungen öffnen",
        "安装 Xcode": "Xcode installieren",
        "xcodebuild 不可用": "xcodebuild ist nicht verfügbar",
        "Xcode %@ 尚未验证，若行为异常请反馈":
            "Xcode %@ ist nicht verifiziert – melde bitte alles, was sich seltsam verhält",

        // MARK: 运行前置校验
        "还没有选择项目": "Noch kein Projekt ausgewählt",
        "还没有选择 scheme": "Noch kein scheme ausgewählt",
        "还没有选择运行目标": "Noch kein Ausführungsziel ausgewählt",
        "已取消": "Abgebrochen",
        "App 启动后立即退出": "Die App wurde direkt nach dem Start beendet",
        "App 已退出（退出码 %d）": "Die App wurde beendet (Code %d)",

        // MARK: 工具链错误
        "无法解析 xcodebuild -list 的输出":
            "Die Ausgabe von xcodebuild -list konnte nicht ausgewertet werden",
        "xcodebuild -list 输出中既没有 project 也没有 workspace":
            "Die Ausgabe von xcodebuild -list enthält weder ein project noch ein workspace",
        "无法解析 -showBuildSettings 的输出":
            "Die Ausgabe von -showBuildSettings konnte nicht ausgewertet werden",
        "无法解析 simctl list devices 的输出":
            "Die Ausgabe von simctl list devices konnte nicht ausgewertet werden",
        "无法解析 devicectl list devices 的输出":
            "Die Ausgabe von devicectl list devices konnte nicht ausgewertet werden",
        "读取项目信息失败": "Projektinformationen konnten nicht gelesen werden",
        "读取构建设置失败": "Build-Einstellungen konnten nicht gelesen werden",
        "读取模拟器列表失败": "Die Simulatorliste konnte nicht gelesen werden",
        "读取真机列表失败": "Die Geräteliste konnte nicht gelesen werden",
        "该项目没有可用的 scheme（只有勾选 Shared 的 scheme 才会出现在列表中）":
            "Dieses Projekt hat kein nutzbares scheme (nur als Shared markierte schemes erscheinen in der Liste)",
        "构建设置中没有 PRODUCT_BUNDLE_IDENTIFIER，该 scheme 可能不是可运行的 App target":
            "In den Build-Einstellungen fehlt PRODUCT_BUNDLE_IDENTIFIER – dieses scheme ist womöglich kein ausführbares App-Target",
        "构建设置中缺少 BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME":
            "In den Build-Einstellungen fehlen BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME",
        "模拟器启动超时": "Zeitüberschreitung beim Starten des Simulators",
        "启动模拟器失败：%@": "Der Simulator konnte nicht gestartet werden: %@",
        "安装到模拟器失败：%@": "Installation im Simulator fehlgeschlagen: %@",
        "在模拟器上启动 App 失败：%@": "App konnte im Simulator nicht gestartet werden: %@",
        "安装到设备失败：%@": "Installation auf dem Gerät fehlgeschlagen: %@",
        "在设备上启动 App 失败：%@": "App konnte auf dem Gerät nicht gestartet werden: %@",
        "无法执行 %@：%@": "%@ konnte nicht ausgeführt werden: %@",
        "%@ 执行超时（%ds）": "%@ hat das Zeitlimit überschritten (%d s)",
        "%@ 退出码 %d": "%@ endete mit Code %d",
        "未知错误": "Unbekannter Fehler",

        // MARK: 工程与书签
        "%@ 不是 Xcode 工程": "%@ ist kein Xcode-Projekt",
        "%@ 中找不到 .xcodeproj 或 .xcworkspace":
            "In %@ wurde kein .xcodeproj oder .xcworkspace gefunden",
        "书签已失效，请重新选择项目":
            "Das Lesezeichen ist veraltet – wähle das Projekt erneut aus",
        "无法为 %@ 创建书签": "Für %@ konnte kein Lesezeichen erstellt werden",
        "找不到 %@": "%@ nicht gefunden",

        // MARK: ErrorTranslator（可执行的下一步）
        "设备已锁屏，请解锁后重试":
            "Das Gerät ist gesperrt – entsperre es und versuche es erneut",
        "安装被拒绝：签名与设备不匹配，检查 provisioning profile 是否包含该设备":
            "Installation abgelehnt: Die Signatur passt nicht zum Gerät. Prüfe, ob das provisioning profile dieses Gerät enthält",
        "provisioning profile 未包含任何设备，请在开发者后台添加该设备":
            "Das provisioning profile enthält keine Geräte – füge dieses Gerät im Developer-Portal hinzu",
        "缺少可用的 provisioning profile，请在 Xcode 中打开 Signing & Capabilities 配置自动签名":
            "Kein nutzbares provisioning profile – öffne in Xcode Signing & Capabilities und aktiviere die automatische Signierung",
        "签名失败：真机构建必须配置有效的签名证书与描述文件":
            "Signieren fehlgeschlagen: Builds für echte Geräte brauchen ein gültiges Signaturzertifikat und ein provisioning profile",
        "找不到签名证书，请在 Xcode 的账户设置中登录并下载证书":
            "Kein Signaturzertifikat gefunden – melde dich in den Account-Einstellungen von Xcode an und lade deine Zertifikate",
        "设备的开发者磁盘映像未挂载，通常重新插拔或重启设备可恢复":
            "Das Developer Disk Image des Geräts ist nicht geladen – neu anstecken oder das Gerät neu starten hilft meist",
        "设备未开启「开发者模式」，请在 设置 › 隐私与安全性 › 开发者模式 中打开":
            "Der Entwicklermodus ist auf dem Gerät aus – aktiviere ihn unter Einstellungen › Datenschutz & Sicherheit › Entwicklermodus",
        "设备未连接或未信任本机，请检查连接后重试":
            "Das Gerät ist nicht verbunden oder vertraut diesem Mac nicht – prüfe die Verbindung und versuche es erneut",
        "该模拟器的数据已丢失，请在 Xcode › Devices and Simulators 中删除后重建":
            "Die Daten dieses Simulators fehlen – lösche ihn in Xcode › Devices and Simulators und erstelle ihn neu",
        "模拟器无法启动，尝试在 Simulator 中执行 Device › Erase All Content and Settings":
            "Der Simulator startet nicht – versuche im Simulator Device › Erase All Content and Settings",
        "App 尚未安装到该设备，请重新运行一次":
            "Die App ist auf diesem Gerät noch nicht installiert – führe sie noch einmal aus",
        "该 scheme 未配置当前 action，请检查 scheme 的 Build/Run 设置":
            "Dieses scheme ist für die aktuelle Aktion nicht konfiguriert – prüfe seine Build/Run-Einstellungen",
        "工程中找不到该 scheme，可能已被重命名或未勾选 Shared":
            "Das scheme ist nicht im Projekt – es wurde vielleicht umbenannt oder ist nicht als Shared markiert",
        "找不到匹配的运行目标，设备可能已断开或模拟器已被删除":
            "Kein passendes Ziel gefunden – das Gerät ist womöglich getrennt oder der Simulator gelöscht",
        "工程路径无效，文件可能已被移动或删除":
            "Der Projektpfad ist ungültig – die Dateien wurden womöglich verschoben oder gelöscht",
        "找不到构建产物，请重新构建":
            "Build-Produkt nicht gefunden – bitte erneut bauen",
    ]
}
