//
//  L10nTable+tr.swift
//  XcodeControl
//

extension L10nTable {

    static let tr: [String: String] = [
        // MARK: 主界面三元素
        "运行": "Çalıştır",
        "停止": "Durdur",
        "选择设备": "Aygıt Seç",
        "清理后构建": "Temizle ve derle",
        "模块缓存缺失，正在清理并重试": "Modül önbelleği eksik. Temizlenip yeniden deneniyor…",
        "运行（长按可清理后构建）": "Çalıştır (basılı tutarak önce temizle)",
        "重新运行（长按可清理后构建）": "Yeniden Çalıştır (basılı tutarak önce temizle)",
        "取消构建": "Derlemeyi İptal Et",
        "停止运行": "Çalışmayı Durdur",
        "正在构建…": "Derleniyor…",

        // MARK: 运行状态
        "Building": "Derleniyor",
        "Installing": "Yükleniyor",
        "Launching": "Başlatılıyor",
        "Running": "Çalışıyor",
        "Failed": "Başarısız",
        "准备": "Hazırlanıyor",
        "解析依赖": "Bağımlılıklar Çözümleniyor",
        "编译 Swift": "Swift Derleniyor",
        "编译 C/ObjC": "C/ObjC Derleniyor",
        "编译资源": "Kaynaklar Derleniyor",
        "编译界面": "Arayüz Derleniyor",
        "处理 Info.plist": "Info.plist İşleniyor",
        "运行脚本": "Betik Çalıştırılıyor",
        "链接": "Bağlanıyor",
        "签名": "İmzalanıyor",
        "收尾": "Tamamlanıyor",
        "校验": "Doğrulanıyor",

        // MARK: 设备
        "模拟器": "Simülatörler",
        "已连接设备": "Bağlı Aygıtlar",
        "本机": "Bu Mac",
        "我的 Mac": "Mac'im",
        "已启动": "Başlatıldı",
        "已连接": "Bağlı",
        "未连接": "Bağlı değil",
        "搜索设备": "Aygıt ara",
        "刷新设备列表": "Aygıt listesini yenile",
        "没有匹配的设备": "Eşleşen aygıt yok",
        "没有可用设备": "Kullanılabilir aygıt yok",
        "未命名设备": "Adsız Aygıt",

        // MARK: 项目
        "项目": "Proje",
        "项目列表": "Projeler",
        "未选择项目": "Proje seçilmedi",
        "尚未选择项目": "Henüz proje seçilmedi",
        "添加项目…": "Proje Ekle…",
        "管理项目…": "Projeleri Yönet…",
        "选择项目…": "Proje Seç…",
        "在 Xcode 中打开": "Xcode'da Aç",
        "从列表移除": "Listeden Kaldır",
        "从列表中删除": "Listeden Kaldır",
        "路径已失效": "Yol geçersiz",
        "路径失效": "Yol geçersiz",
        "%@（路径已失效）": "%@ (yol geçersiz)",
        "设为当前项目": "Geçerli Proje Yap",
        "当前": "Geçerli",
        "选择或拖入 Xcode 项目": "Xcode projesi seçin veya sürükleyin",
        "拖入 .xcodeproj / .xcworkspace，或项目文件夹":
            ".xcodeproj / .xcworkspace ya da proje klasörü bırakın",
        "正在解析…": "Çözümleniyor…",
        "未解析到 scheme": "Scheme bulunamadı",
        "解析失败，见悬浮窗": "Çözümleme başarısız — panele bakın",

        // MARK: Git
        "当前项目不在 Git 仓库中": "Geçerli proje bir Git deposunda değil",
        "无法读取当前 Git 分支": "Geçerli Git dalı okunamadı",
        "分支已不存在，请刷新列表后重试": "Dal artık mevcut değil. Listeyi yenileyip tekrar deneyin",
        "当前修改会被覆盖，请先提交或暂存后再切换分支":
            "Geçerli değişikliklerin üzerine yazılacak. Dal değiştirmeden önce commit veya stash yapın",
        "仓库有未解决的冲突，请先处理后再切换分支":
            "Depoda çözülmemiş çakışmalar var. Dal değiştirmeden önce çözün",
        "该分支正在另一个 Git worktree 中使用": "Bu dal başka bir Git worktree tarafından kullanılıyor",
        "切换分支失败：%@": "Dal değiştirilemedi: %@",
        "切换 Git 分支": "Git dalını değiştir",
        "本地分支": "Yerel dallar",
        "正在读取分支…": "Dallar yükleniyor…",
        "没有本地分支": "Yerel dal yok",
        "刷新分支列表": "Dal listesini yenile",
        "同步 Worktree 项目": "Worktree Projelerini Eşzamanla",
        "Git worktree 路径已失效，请先在终端清理该 worktree":
            "Git worktree yolu geçersiz. Önce Terminal’de bu worktree’yi temizleyin",
        "worktree": "worktree",
        "Git 操作详情：%@": "Git işlemi ayrıntıları: %@",
        "构建进行中，停止后可切换分支":
            "Derleme devam ediyor. Dal değiştirmeden önce durdurun",

        // MARK: 日志
        "日志": "Günlük",
        "收起日志": "Günlüğü Daralt",
        "拷贝完整日志": "Tüm Günlüğü Kopyala",
        "拷贝错误信息": "Hatayı Kopyala",
        "拷贝命令": "Komutu Kopyala",
        "查看完整日志": "Tüm Günlüğü Görüntüle",
        "过滤": "Filtrele",
        "自动滚动：开": "Otomatik kaydırma: Açık",
        "自动滚动：关": "Otomatik kaydırma: Kapalı",

        // MARK: 通用动作
        "设置": "Ayarlar",
        "设置…": "Ayarlar…",
        "关闭": "Kapat",
        "取消": "İptal",
        "完成": "Bitti",
        "清除": "Temizle",
        "清理": "Temizle",
        "清理…": "Temizle…",
        "清空": "Tümünü Temizle",
        "添加": "Ekle",
        "扫描": "Tara",
        "扫描文件夹…": "Klasör Tara…",
        "选择": "Seç",
        "好的": "Tamam",
        "启用": "Etkinleştir",
        "打开系统设置": "Sistem Ayarları'nı Aç",
        "在 Finder 中显示": "Finder'da Göster",
        "显示悬浮窗": "Paneli Göster",
        "隐藏悬浮窗": "Paneli Gizle",
        "退出 XcodeControl": "XcodeControl'den Çık",
        "其他…": "Diğer…",
        "自定义": "Özel",
        "自定义…": "Özel…",
        "默认": "Varsayılan",
        "未知": "Bilinmiyor",
        "秒": "sn",
        "空格": "Boşluk",
        "语言": "Dil",
        "界面语言": "Arayüz Dili",
        "跟随系统": "Sistemi İzle",

        // MARK: 设置页
        "通用": "Genel",
        "构建": "Derleme",
        "行为": "Davranış",
        "位置": "Konumlar",
        "关于": "Hakkında",
        "启动": "Başlangıç",
        "浮窗": "Panel",
        "设备": "Aygıtlar",
        "偏好设置": "Tercihler",
        "开机自启动": "Girişte Başlat",
        "启动时显示浮窗": "Açılışta paneli göster",
        "启动时打开设置": "Açılışta ayarları aç",
        "显示 Git 分支": "Git dalını göster",
        "失焦时降低不透明度": "Etkin değilken soluklaştır",
        "不透明度": "Opaklık",
        "重置窗口位置": "Pencere Konumunu Sıfırla",
        "缓冲行数": "Arabellek satırları",
        "刷新间隔": "Yenileme aralığı",
        "开机自启动由系统「登录项」管理；首次开启可能需要你在系统设置里确认。":
            "Girişte başlatma, sistemin Giriş Öğeleri özelliğiyle yönetilir; ilk kez açtığınızda Sistem Ayarları'nda onaylamanız gerekebilir.",
        "需要在系统设置中允许登录项。":
            "Giriş öğesine Sistem Ayarları'nda izin vermeniz gerekiyor.",
        "已申请开机自启，请在系统设置 › 通用 › 登录项中允许。":
            "Girişte başlatma istendi. Sistem Ayarları › Genel › Giriş Öğeleri bölümünden izin verin.",
        "超出后丢弃最旧的行。": "Bu sınır aşılınca en eski satırlar atılır.",
        "构建期间自动暂停轮询。低于 2 秒无效。":
            "Derleme sırasında yoklama duraklatılır. 2 saniyenin altındaki değerler etkisizdir.",

        // MARK: 设置页 · 构建
        "附着控制台输出": "Konsol çıktısını iliştir",
        "附着后可在日志面板看到 App 的实时输出，代价是拿不到进程 PID。关闭则以分离方式启动。":
            "İliştirildiğinde App'in canlı çıktısı günlük panelinde görünür; karşılığında işlem PID değeri alınamaz. Kapatırsanız ayrık modda başlatılır.",
        "失败处理": "Başarısız olunca",
        "构建失败时自动展开日志": "Derleme başarısız olunca günlüğü aç",
        "失败后日志面板自动弹出，方便立刻看到错误。":
            "Günlük paneli kendiliğinden açılır, böylece hatayı hemen görürsünüz.",

        // MARK: 设置页 · 行为
        "构建成功时": "Başarılı olunca",
        "构建失败时": "Başarısız olunca",
        "发送通知": "Bildirim gönder",
        "播放声音": "Ses çal",
        "浮窗隐藏时同样生效。": "Panel gizliyken de geçerlidir.",
        "全局快捷键": "Global Kısayollar",
        "已被占用": "Zaten kullanımda",
        "需要通知权限": "Bildirim İzni Gerekiyor",
        "系统拒绝了通知权限。请在系统设置中为 XcodeControl 开启通知，然后再试。":
            "Sistem bildirim iznini reddetti. Sistem Ayarları'nda XcodeControl için bildirimleri açın, sonra yeniden deneyin.",
        "构建成功": "Derleme Başarılı",
        "构建失败": "Derleme Başarısız",

        // MARK: 设置页 · 位置
        "命令行工具": "Command Line Tools",
        "Derived Data 位置": "Derived Data Konumu",
        "构建设置缓存": "Derleme Ayarları Önbelleği",
        "系统默认（xcode-select）": "Sistem varsayılanı (xcode-select)",
        "选择 Xcode.app": "Xcode.app'i Seç",
        "选择 Derived Data 根目录": "Derived Data Kök Dizinini Seç",
        "选择自定义目录": "Özel Dizin Seç",
        "更改仅影响本应用的 DEVELOPER_DIR，不会改动系统的 xcode-select。":
            "Bu değişiklik yalnızca bu uygulamanın DEVELOPER_DIR değerini etkiler; sistemin xcode-select ayarına dokunulmaz.",
        "清理 Derived Data？": "Derived Data temizlensin mi?",
        "清除构建设置缓存？": "Derleme ayarları önbelleği temizlensin mi?",
        "回收": "Geri kazan",
        "回收…": "Geri kazan…",
        "%d 天未构建": "%d gündür derlenmedi",
        "全部清除…": "Tümünü sil…",
        "清除全部 Derived Data？": "Tüm Derived Data silinsin mi?",
        "Xcode 自己从不回收 Derived Data：工程移动或删除后，旧缓存会一直留在磁盘上。":
            "Xcode, Derived Data’yı kendiliğinden hiç temizlemez: bir proje taşındıktan veya silindikten sonra eski önbellek diskte sonsuza dek kalır.",
        "自动回收": "Otomatik geri kazanım",
        "回收已删除工程的缓存": "Silinmiş projelerin önbelleğini geri kazan",
        "回收长期未构建的缓存": "Uzun süredir derlenmeyen önbellekleri geri kazan",
        "这一项删的是仍在使用的工程的缓存，代价是下次全量重编。构建成功后在后台执行，每天最多一次。":
            "Bu, hâlâ kullanılan projelerin önbelleğini siler; bedeli bir sonraki seferde tam yeniden derlemedir. Başarılı bir derlemeden sonra arka planda, günde en fazla bir kez çalışır.",
        "超过 %d 天未构建": "%d günden uzun süredir derlenmedi",
        "依据缓存里记录的工程路径判定；路径已不存在即回收。判不出归属的目录会跳过。":
            "Her önbellekte kayıtlı proje yoluna göre karar verilir; yol artık yoksa geri kazanılır. Sahipliği belirlenemeyen dizinler atlanır.",
        "自定义目录由本应用管理，可精确判定归属；不属于任何已托管工程的目录即回收。":
            "Özel dizin bu uygulama tarafından yönetildiğinden sahiplik tam olarak belirlenir; yönetilen hiçbir projeye ait olmayan dizinler geri kazanılır.",
        "没有可回收的 Derived Data": "Geri kazanılacak Derived Data yok",
        "所有缓存都属于仍在使用的工程。": "Tüm önbellekler hâlâ kullanılan projelere ait.",
        "回收 %d 份 Derived Data？": "%d Derived Data önbelleği geri kazanılsın mı?",
        "共可释放 %@。此操作不可撤销。": "Toplam %@ boşaltılabilir. Bu işlem geri alınamaz.",
        "已回收 %d 份无用的 Derived Data，释放 %@":
            "%d gereksiz Derived Data önbelleği geri kazanıldı, %@ boşaltıldı",
        "工程已不存在": "Proje artık mevcut değil",
        "…另有 %d 份": "…ve %d tane daha",
        "启动后获取": "Açılışta okunur",
        "路径": "Yol",
        "版本": "Sürüm",
        "检查更新…": "Güncellemeleri Denetle…",
        "反馈问题": "Sorun Bildir",
        "请通过 GitHub Issues 反馈问题，或在代码仓库提 PR。":
            "Sorunları GitHub Issues üzerinden bildirin ya da depoya bir PR açın.",

        // MARK: 设置页 · 项目
        "清空项目": "Projeleri Temizle",
        "清空全部项目？": "Tüm projeler temizlensin mi?",
        "列表中的 %d 个项目都会移除，当前项目也会取消。":
            "Listedeki %d projenin tümü kaldırılacak ve geçerli proje seçimi kalkacak.",
        "还没有项目。拖入工程文件/文件夹，或用下方按钮添加。":
            "Henüz proje yok. Bir proje dosyası ya da klasörü bırakın veya aşağıdaki düğmeyle ekleyin.",
        "拖拽行可调整顺序；也可拖入工程文件或文件夹添加。":
            "Sıralamayı değiştirmek için satırları sürükleyin; proje dosyası veya klasörü bırakarak da ekleyebilirsiniz.",
        "支持拖入 .xcodeproj / .xcworkspace，或包含它们的文件夹。":
            ".xcodeproj / .xcworkspace dosyaları ya da bunları içeren klasörler bırakılabilir.",
        "选择 .xcodeproj / .xcworkspace，或包含它们的目录":
            ".xcodeproj / .xcworkspace ya da bunları içeren bir dizin seçin",
        "选择 .xcodeproj 或 .xcworkspace": ".xcodeproj ya da .xcworkspace seçin",
        "选择要扫描的根目录。同目录下若同时有 workspace 与 xcodeproj，只导入 workspace。":
            "Taranacak kök dizini seçin. Bir klasörde hem workspace hem xcodeproj varsa yalnızca workspace içe aktarılır.",
        "正在扫描…": "Taranıyor…",
        "已添加 %d 个项目。": "%d proje eklendi.",
        "已通过拖放加入 %d 个项目。": "Sürükleyip bırakarak %d proje eklendi.",
        "扫描完成：新增 %d 个，已存在 %d 个。":
            "Tarama tamamlandı: %d eklendi, %d zaten vardı.",
        "Worktree 同步完成：新增项目 %d 个，已存在 %d 个，未找到工程的 worktree %d 个。":
            "Worktree eşzamanlama tamamlandı: %d proje eklendi, %d zaten vardı, %d worktree içinde proje bulunamadı.",
        "没有新项目加入（可能已在列表中）。":
            "Yeni proje eklenmedi (zaten listede olabilirler).",
        "没有新项目加入（可能已在列表中或无法识别）。":
            "Yeni proje eklenmedi (zaten listede olabilirler ya da tanınmadılar).",
        "未在该目录下发现可导入的工程。":
            "Bu dizinde içe aktarılabilecek proje bulunamadı.",
        "未识别到 .xcodeproj / .xcworkspace": ".xcodeproj / .xcworkspace tanınmadı",

        // MARK: 环境错误
        "正在检查 Xcode 环境…": "Xcode ortamı denetleniyor…",
        "环境不可用": "Ortam kullanılamıyor",
        "环境检查失败": "Ortam denetimi başarısız",
        "未能确定 Xcode 位置": "Xcode konumu belirlenemedi",
        "当前选中的是 Command Line Tools，不是完整的 Xcode":
            "Şu anda seçili olan Command Line Tools, tam bir Xcode değil",
        "请选择要使用的 Xcode": "Kullanılacak Xcode’u seçin",
        "未找到完整的 Xcode": "Tam bir Xcode kurulumu bulunamadı",
        "前往设置": "Ayarları Aç",
        "安装 Xcode": "Xcode’u yükle",
        "xcodebuild 不可用": "xcodebuild kullanılamıyor",
        "Xcode %@ 尚未验证，若行为异常请反馈":
            "Xcode %@ sürümü doğrulanmadı — beklenmedik bir davranış görürseniz bildirin",

        // MARK: 运行前置校验
        "还没有选择项目": "Henüz proje seçilmedi",
        "还没有选择 scheme": "Henüz scheme seçilmedi",
        "还没有选择运行目标": "Henüz çalıştırma hedefi seçilmedi",
        "已取消": "İptal edildi",
        "App 启动后立即退出": "App başlar başlamaz kapandı",
        "App 已退出（退出码 %d）": "App kapandı (çıkış kodu %d)",

        // MARK: 工具链错误
        "无法解析 xcodebuild -list 的输出": "xcodebuild -list çıktısı ayrıştırılamadı",
        "xcodebuild -list 输出中既没有 project 也没有 workspace":
            "xcodebuild -list çıktısında ne project ne de workspace var",
        "无法解析 -showBuildSettings 的输出": "-showBuildSettings çıktısı ayrıştırılamadı",
        "无法解析 simctl list devices 的输出": "simctl list devices çıktısı ayrıştırılamadı",
        "无法解析 devicectl list devices 的输出":
            "devicectl list devices çıktısı ayrıştırılamadı",
        "读取项目信息失败": "Proje bilgileri okunamadı",
        "读取构建设置失败": "Derleme ayarları okunamadı",
        "读取模拟器列表失败": "Simülatör listesi okunamadı",
        "读取真机列表失败": "Aygıt listesi okunamadı",
        "该项目没有可用的 scheme（只有勾选 Shared 的 scheme 才会出现在列表中）":
            "Bu projede kullanılabilir scheme yok (listede yalnızca Shared işaretli scheme'ler görünür)",
        "构建设置中没有 PRODUCT_BUNDLE_IDENTIFIER，该 scheme 可能不是可运行的 App target":
            "Derleme ayarlarında PRODUCT_BUNDLE_IDENTIFIER yok — bu scheme çalıştırılabilir bir App target olmayabilir",
        "构建设置中缺少 BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME":
            "Derleme ayarlarında BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME eksik",
        "模拟器启动超时": "Simülatörün açılması zaman aşımına uğradı",
        "启动模拟器失败：%@": "Simülatör başlatılamadı: %@",
        "安装到模拟器失败：%@": "Simülatöre yükleme başarısız: %@",
        "在模拟器上启动 App 失败：%@": "App simülatörde başlatılamadı: %@",
        "安装到设备失败：%@": "Aygıta yükleme başarısız: %@",
        "在设备上启动 App 失败：%@": "App aygıtta başlatılamadı: %@",
        "无法执行 %@：%@": "%@ çalıştırılamadı: %@",
        "%@ 执行超时（%ds）": "%@ zaman aşımına uğradı (%d sn)",
        "%@ 退出码 %d": "%@ çıkış kodu %d",
        "未知错误": "Bilinmeyen hata",

        // MARK: 工程与书签
        "%@ 不是 Xcode 工程": "%@ bir Xcode projesi değil",
        "%@ 中找不到 .xcodeproj 或 .xcworkspace":
            "%@ içinde .xcodeproj ya da .xcworkspace bulunamadı",
        "书签已失效，请重新选择项目": "Yer imi geçersiz — projeyi yeniden seçin",
        "无法为 %@ 创建书签": "%@ için yer imi oluşturulamadı",
        "找不到 %@": "%@ bulunamadı",

        // MARK: ErrorTranslator（可执行的下一步）
        "设备已锁屏，请解锁后重试": "Aygıt kilitli — kilidini açıp yeniden deneyin",
        "安装被拒绝：签名与设备不匹配，检查 provisioning profile 是否包含该设备":
            "Yükleme reddedildi: imza aygıtla eşleşmiyor. provisioning profile içinde bu aygıtın olup olmadığını denetleyin",
        "provisioning profile 未包含任何设备，请在开发者后台添加该设备":
            "provisioning profile hiçbir aygıt içermiyor — bu aygıtı geliştirici portalında ekleyin",
        "缺少可用的 provisioning profile，请在 Xcode 中打开 Signing & Capabilities 配置自动签名":
            "Kullanılabilir provisioning profile yok — Xcode'da Signing & Capabilities bölümünü açıp otomatik imzalamayı ayarlayın",
        "签名失败：真机构建必须配置有效的签名证书与描述文件":
            "İmzalama başarısız: aygıt derlemeleri için geçerli bir imzalama sertifikası ve provisioning profile gerekir",
        "找不到签名证书，请在 Xcode 的账户设置中登录并下载证书":
            "İmzalama sertifikası bulunamadı — Xcode'un hesap ayarlarında oturum açıp sertifikalarınızı indirin",
        "设备的开发者磁盘映像未挂载，通常重新插拔或重启设备可恢复":
            "Aygıtın geliştirici disk imajı bağlanmamış — kabloyu yeniden takmak ya da aygıtı yeniden başlatmak genelde çözer",
        "设备未开启「开发者模式」，请在 设置 › 隐私与安全性 › 开发者模式 中打开":
            "Aygıtta Geliştirici Modu kapalı — Ayarlar › Gizlilik ve Güvenlik › Geliştirici Modu bölümünden açın",
        "设备未连接或未信任本机，请检查连接后重试":
            "Aygıt bağlı değil ya da bu Mac'e güvenmiyor — bağlantıyı denetleyip yeniden deneyin",
        "该模拟器的数据已丢失，请在 Xcode › Devices and Simulators 中删除后重建":
            "Bu simülatörün verileri kayıp — Xcode › Devices and Simulators bölümünde silip yeniden oluşturun",
        "模拟器无法启动，尝试在 Simulator 中执行 Device › Erase All Content and Settings":
            "Simülatör başlatılamıyor — Simulator'da Device › Erase All Content and Settings adımını deneyin",
        "App 尚未安装到该设备，请重新运行一次":
            "App henüz o aygıta yüklenmedi — bir kez daha çalıştırın",
        "该 scheme 未配置当前 action，请检查 scheme 的 Build/Run 设置":
            "Bu scheme geçerli action için yapılandırılmamış — scheme'in Build/Run ayarlarını denetleyin",
        "工程中找不到该 scheme，可能已被重命名或未勾选 Shared":
            "Scheme projede yok — adı değiştirilmiş ya da Shared olarak işaretlenmemiş olabilir",
        "找不到匹配的运行目标，设备可能已断开或模拟器已被删除":
            "Eşleşen çalıştırma hedefi yok — aygıtın bağlantısı kesilmiş ya da simülatör silinmiş olabilir",
        "工程路径无效，文件可能已被移动或删除":
            "Proje yolu geçersiz — dosyalar taşınmış ya da silinmiş olabilir",
        "找不到构建产物，请重新构建": "Derleme ürünü bulunamadı — yeniden derleyin",
    ]
}
