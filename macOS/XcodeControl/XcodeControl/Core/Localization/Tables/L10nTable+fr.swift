//
//  L10nTable+fr.swift
//  XcodeControl
//

extension L10nTable {

    static let fr: [String: String] = [
        // MARK: 主界面三元素
        "运行": "Exécuter",
        "停止": "Arrêter",
        "选择设备": "Choisir un appareil",
        "清理后构建": "Nettoyer et compiler",
        "模块缓存缺失，正在清理并重试": "Cache de modules manquant. Nettoyage et nouvelle tentative…",
        "运行（长按可清理后构建）": "Exécuter (maintenir pour nettoyer d'abord)",
        "重新运行（长按可清理后构建）": "Réexécuter (maintenir pour nettoyer d'abord)",
        "取消构建": "Annuler la compilation",
        "停止运行": "Arrêter l'exécution",
        "正在构建…": "Compilation…",

        // MARK: 运行状态
        "Building": "Compilation",
        "Installing": "Installation",
        "Launching": "Lancement",
        "Running": "Exécution",
        "Failed": "Échec",
        "准备": "Préparation",
        "解析依赖": "Résolution des dépendances",
        "编译 Swift": "Compilation Swift",
        "编译 C/ObjC": "Compilation C/ObjC",
        "编译资源": "Compilation des ressources",
        "编译界面": "Compilation des interfaces",
        "处理 Info.plist": "Traitement d'Info.plist",
        "运行脚本": "Exécution du script",
        "链接": "Édition de liens",
        "签名": "Signature",
        "收尾": "Finalisation",
        "校验": "Validation",

        // MARK: 设备
        "模拟器": "Simulateurs",
        "已连接设备": "Appareils connectés",
        "本机": "Ce Mac",
        "我的 Mac": "Mon Mac",
        "已启动": "Démarré",
        "已连接": "Connecté",
        "未连接": "Déconnecté",
        "搜索设备": "Rechercher un appareil",
        "刷新设备列表": "Actualiser la liste des appareils",
        "没有匹配的设备": "Aucun appareil correspondant",
        "没有可用设备": "Aucun appareil disponible",
        "未命名设备": "Appareil sans nom",

        // MARK: 项目
        "项目": "Projet",
        "项目列表": "Projets",
        "未选择项目": "Aucun projet sélectionné",
        "尚未选择项目": "Aucun projet sélectionné pour l'instant",
        "添加项目…": "Ajouter un projet…",
        "管理项目…": "Gérer les projets…",
        "选择项目…": "Choisir un projet…",
        "在 Xcode 中打开": "Ouvrir dans Xcode",
        "从列表移除": "Retirer de la liste",
        "从列表中删除": "Retirer de la liste",
        "路径已失效": "Chemin indisponible",
        "路径失效": "Chemin indisponible",
        "%@（路径已失效）": "%@ (chemin indisponible)",
        "设为当前项目": "Définir comme projet actuel",
        "当前": "Actuel",
        "选择或拖入 Xcode 项目": "Choisir ou déposer un projet Xcode",
        "拖入 .xcodeproj / .xcworkspace，或项目文件夹":
            "Déposez un .xcodeproj / .xcworkspace, ou un dossier de projet",
        "正在解析…": "Résolution…",
        "未解析到 scheme": "Aucun scheme trouvé",
        "解析失败，见悬浮窗": "Échec de la résolution — voir le panneau",

        // MARK: Git
        "当前项目不在 Git 仓库中": "Le projet actuel ne se trouve pas dans un dépôt Git",
        "无法读取当前 Git 分支": "Impossible de lire la branche Git actuelle",
        "分支已不存在，请刷新列表后重试": "La branche n’existe plus. Actualisez la liste puis réessayez",
        "当前修改会被覆盖，请先提交或暂存后再切换分支":
            "Les modifications actuelles seraient écrasées. Validez-les ou remisez-les avant de changer de branche",
        "仓库有未解决的冲突，请先处理后再切换分支":
            "Le dépôt contient des conflits non résolus. Résolvez-les avant de changer de branche",
        "该分支正在另一个 Git worktree 中使用": "Cette branche est utilisée dans un autre worktree Git",
        "切换分支失败：%@": "Échec du changement de branche : %@",
        "切换 Git 分支": "Changer de branche Git",
        "本地分支": "Branches locales",
        "正在读取分支…": "Chargement des branches…",
        "没有本地分支": "Aucune branche locale",
        "刷新分支列表": "Actualiser la liste des branches",
        "同步 Worktree 项目": "Synchroniser les projets worktree",
        "Git worktree 路径已失效，请先在终端清理该 worktree":
            "Le chemin du worktree Git n’est plus valide. Nettoyez d’abord ce worktree dans Terminal",
        "worktree": "worktree",
        "Git 操作详情：%@": "Détails de l’opération Git : %@",
        "构建进行中，停止后可切换分支":
            "Une compilation est en cours. Arrêtez-la avant de changer de branche",

        // MARK: 日志
        "日志": "Journal",
        "收起日志": "Masquer le journal",
        "拷贝完整日志": "Copier tout le journal",
        "拷贝错误信息": "Copier l'erreur",
        "拷贝命令": "Copier la commande",
        "查看完整日志": "Voir le journal complet",
        "过滤": "Filtrer",
        "自动滚动：开": "Défilement auto : activé",
        "自动滚动：关": "Défilement auto : désactivé",

        // MARK: 通用动作
        "设置": "Réglages",
        "设置…": "Réglages…",
        "关闭": "Fermer",
        "取消": "Annuler",
        "完成": "Terminé",
        "清除": "Effacer",
        "清理": "Nettoyer",
        "清理…": "Nettoyer…",
        "清空": "Tout effacer",
        "添加": "Ajouter",
        "扫描": "Analyser",
        "扫描文件夹…": "Analyser un dossier…",
        "选择": "Choisir",
        "好的": "OK",
        "启用": "Activer",
        "打开系统设置": "Ouvrir Réglages Système",
        "在 Finder 中显示": "Afficher dans le Finder",
        "显示悬浮窗": "Afficher le panneau",
        "隐藏悬浮窗": "Masquer le panneau",
        "退出 XcodeControl": "Quitter XcodeControl",
        "其他…": "Autre…",
        "自定义": "Personnalisé",
        "自定义…": "Personnalisé…",
        "默认": "Par défaut",
        "未知": "Inconnu",
        "秒": "s",
        "空格": "Espace",
        "语言": "Langue",
        "界面语言": "Langue de l'interface",
        "跟随系统": "Suivre le système",

        // MARK: 设置页
        "通用": "Général",
        "构建": "Compilation",
        "行为": "Comportement",
        "位置": "Emplacements",
        "关于": "À propos",
        "启动": "Démarrage",
        "浮窗": "Panneau",
        "设备": "Appareils",
        "偏好设置": "Préférences",
        "开机自启动": "Ouvrir à la session",
        "启动时显示浮窗": "Afficher le panneau au démarrage",
        "启动时打开设置": "Ouvrir les réglages au démarrage",
        "显示 Git 分支": "Afficher la branche Git",
        "失焦时降低不透明度": "Atténuer quand inactif",
        "不透明度": "Opacité",
        "重置窗口位置": "Réinitialiser la position de la fenêtre",
        "缓冲行数": "Lignes du tampon",
        "刷新间隔": "Intervalle d'actualisation",
        "开机自启动由系统「登录项」管理；首次开启可能需要你在系统设置里确认。":
            "L'ouverture à la session est gérée par les éléments d'ouverture du système ; la première activation peut demander une confirmation dans Réglages Système.",
        "需要在系统设置中允许登录项。":
            "Vous devez autoriser l'élément d'ouverture dans Réglages Système.",
        "已申请开机自启，请在系统设置 › 通用 › 登录项中允许。":
            "Ouverture à la session demandée. Autorisez-la dans Réglages Système › Général › Ouverture.",
        "超出后丢弃最旧的行。":
            "Au-delà de cette limite, les lignes les plus anciennes sont supprimées.",
        "构建期间自动暂停轮询。低于 2 秒无效。":
            "L'interrogation est suspendue pendant les compilations. En dessous de 2 secondes, sans effet.",

        // MARK: 设置页 · 构建
        "附着控制台输出": "Attacher la sortie console",
        "附着后可在日志面板看到 App 的实时输出，代价是拿不到进程 PID。关闭则以分离方式启动。":
            "L'attachement affiche la sortie en direct de l'App dans le journal, au prix de ne pas obtenir le PID du processus. Désactivez-le pour un lancement détaché.",
        "失败处理": "En cas d'échec",
        "构建失败时自动展开日志": "Déplier le journal si la compilation échoue",
        "失败后日志面板自动弹出，方便立刻看到错误。":
            "Le journal s'ouvre automatiquement pour voir l'erreur immédiatement.",

        // MARK: 设置页 · 行为
        "构建成功时": "En cas de succès",
        "构建失败时": "En cas d'échec",
        "发送通知": "Envoyer une notification",
        "播放声音": "Jouer un son",
        "浮窗隐藏时同样生效。": "S'applique même lorsque le panneau est masqué.",
        "全局快捷键": "Raccourcis globaux",
        "已被占用": "Déjà utilisé",
        "需要通知权限": "Autorisation de notification requise",
        "系统拒绝了通知权限。请在系统设置中为 XcodeControl 开启通知，然后再试。":
            "Le système a refusé les notifications. Activez-les pour XcodeControl dans Réglages Système, puis réessayez.",
        "构建成功": "Compilation réussie",
        "构建失败": "Échec de la compilation",

        // MARK: 设置页 · 位置
        "命令行工具": "Command Line Tools",
        "Derived Data 位置": "Emplacement de Derived Data",
        "构建设置缓存": "Cache des réglages de compilation",
        "系统默认（xcode-select）": "Par défaut du système (xcode-select)",
        "选择 Xcode.app": "Choisir Xcode.app",
        "选择 Derived Data 根目录": "Choisir la racine de Derived Data",
        "选择自定义目录": "Choisir un dossier personnalisé",
        "更改仅影响本应用的 DEVELOPER_DIR，不会改动系统的 xcode-select。":
            "Cela ne change que le DEVELOPER_DIR de cette app ; le xcode-select du système reste inchangé.",
        "清理 Derived Data？": "Nettoyer Derived Data ?",
        "清除构建设置缓存？": "Effacer le cache des réglages de compilation ?",
        "回收": "Nettoyer",
        "回收…": "Nettoyer…",
        "%d 天未构建": "non compilé depuis %d jours",
        "全部清除…": "Tout supprimer…",
        "清除全部 Derived Data？": "Supprimer toutes les Derived Data ?",
        "Xcode 自己从不回收 Derived Data：工程移动或删除后，旧缓存会一直留在磁盘上。":
            "Xcode ne nettoie jamais les Derived Data de lui-même : après le déplacement ou la suppression d’un projet, son cache reste indéfiniment sur le disque.",
        "自动回收": "Nettoyage automatique",
        "回收已删除工程的缓存": "Nettoyer les caches des projets supprimés",
        "回收长期未构建的缓存": "Nettoyer les caches non compilés depuis longtemps",
        "这一项删的是仍在使用的工程的缓存，代价是下次全量重编。构建成功后在后台执行，每天最多一次。":
            "Ceci supprime les caches de projets encore utilisés, au prix d’une recompilation complète la prochaine fois. S’exécute en arrière-plan après une compilation réussie, au plus une fois par jour.",
        "超过 %d 天未构建": "Non compilé depuis plus de %d jours",
        "依据缓存里记录的工程路径判定；路径已不存在即回收。判不出归属的目录会跳过。":
            "Déterminé d’après le chemin du projet enregistré dans chaque cache ; s’il n’existe plus, le cache est nettoyé. Les dossiers dont l’appartenance est indéterminable sont ignorés.",
        "自定义目录由本应用管理，可精确判定归属；不属于任何已托管工程的目录即回收。":
            "Le dossier personnalisé est géré par cette app, l’appartenance est donc exacte ; tout dossier n’appartenant pas à un projet géré est nettoyé.",
        "没有可回收的 Derived Data": "Aucune Derived Data à nettoyer",
        "所有缓存都属于仍在使用的工程。": "Tous les caches appartiennent à des projets encore utilisés.",
        "回收 %d 份 Derived Data？": "Nettoyer %d caches Derived Data ?",
        "共可释放 %@。此操作不可撤销。": "%@ peuvent être libérés au total. Cette action est irréversible.",
        "已回收 %d 份无用的 Derived Data，释放 %@":
            "%d caches Derived Data inutiles nettoyés, %@ libérés",
        "工程已不存在": "Le projet n’existe plus",
        "…另有 %d 份": "…et %d autres",
        "启动后获取": "Lu au démarrage",
        "路径": "Chemin",
        "版本": "Version",
        "检查更新…": "Rechercher les mises à jour…",
        "反馈问题": "Signaler un problème",
        "请通过 GitHub Issues 反馈问题，或在代码仓库提 PR。":
            "Signalez les problèmes via GitHub Issues, ou proposez une PR sur le dépôt.",

        // MARK: 设置页 · 项目
        "清空项目": "Effacer les projets",
        "清空全部项目？": "Effacer tous les projets ?",
        "列表中的 %d 个项目都会移除，当前项目也会取消。":
            "Les %d projets de la liste seront retirés et le projet actuel désélectionné.",
        "还没有项目。拖入工程文件/文件夹，或用下方按钮添加。":
            "Aucun projet pour l'instant. Déposez un fichier ou un dossier de projet, ou ajoutez-en un avec le bouton ci-dessous.",
        "拖拽行可调整顺序；也可拖入工程文件或文件夹添加。":
            "Faites glisser les lignes pour les réordonner ; vous pouvez aussi déposer des fichiers ou des dossiers de projet pour les ajouter.",
        "支持拖入 .xcodeproj / .xcworkspace，或包含它们的文件夹。":
            "Accepte les fichiers .xcodeproj / .xcworkspace, ou les dossiers qui en contiennent.",
        "选择 .xcodeproj / .xcworkspace，或包含它们的目录":
            "Choisir un .xcodeproj / .xcworkspace, ou un dossier qui en contient",
        "选择 .xcodeproj 或 .xcworkspace": "Choisir un .xcodeproj ou un .xcworkspace",
        "选择要扫描的根目录。同目录下若同时有 workspace 与 xcodeproj，只导入 workspace。":
            "Choisissez un dossier racine à analyser. Si un dossier contient à la fois un workspace et un xcodeproj, seul le workspace est importé.",
        "正在扫描…": "Analyse en cours…",
        "已添加 %d 个项目。": "%d projets ajoutés.",
        "已通过拖放加入 %d 个项目。": "%d projets ajoutés par glisser-déposer.",
        "扫描完成：新增 %d 个，已存在 %d 个。":
            "Analyse terminée : %d ajoutés, %d déjà présents.",
        "Worktree 同步完成：新增项目 %d 个，已存在 %d 个，未找到工程的 worktree %d 个。":
            "Synchronisation des worktrees terminée : %d projets ajoutés, %d déjà présents, %d worktrees sans projet.",
        "没有新项目加入（可能已在列表中）。":
            "Aucun nouveau projet ajouté (ils sont peut-être déjà dans la liste).",
        "没有新项目加入（可能已在列表中或无法识别）。":
            "Aucun nouveau projet ajouté (déjà dans la liste, ou non reconnus).",
        "未在该目录下发现可导入的工程。": "Aucun projet importable trouvé dans ce dossier.",
        "未识别到 .xcodeproj / .xcworkspace": "Aucun .xcodeproj / .xcworkspace reconnu",

        // MARK: 环境错误
        "正在检查 Xcode 环境…": "Vérification de l'environnement Xcode…",
        "环境不可用": "Environnement indisponible",
        "环境检查失败": "Échec de la vérification de l'environnement",
        "未能确定 Xcode 位置": "Impossible de déterminer l'emplacement de Xcode",
        "当前选中的是 Command Line Tools，不是完整的 Xcode":
            "Les Command Line Tools sont sélectionnés, pas un Xcode complet",
        "请选择要使用的 Xcode": "Choisissez le Xcode à utiliser",
        "未找到完整的 Xcode": "Aucune installation complète de Xcode n’a été trouvée",
        "前往设置": "Ouvrir les réglages",
        "安装 Xcode": "Installer Xcode",
        "xcodebuild 不可用": "xcodebuild est indisponible",
        "Xcode %@ 尚未验证，若行为异常请反馈":
            "Xcode %@ n'a pas été validé — signalez tout comportement anormal",

        // MARK: 运行前置校验
        "还没有选择项目": "Aucun projet sélectionné pour l'instant",
        "还没有选择 scheme": "Aucun scheme sélectionné pour l'instant",
        "还没有选择运行目标": "Aucune destination d'exécution sélectionnée",
        "已取消": "Annulé",
        "App 启动后立即退出": "L'App a quitté immédiatement après son lancement",
        "App 已退出（退出码 %d）": "L'App a quitté (code %d)",

        // MARK: 工具链错误
        "无法解析 xcodebuild -list 的输出":
            "Impossible d'interpréter la sortie de xcodebuild -list",
        "xcodebuild -list 输出中既没有 project 也没有 workspace":
            "La sortie de xcodebuild -list ne contient ni project ni workspace",
        "无法解析 -showBuildSettings 的输出":
            "Impossible d'interpréter la sortie de -showBuildSettings",
        "无法解析 simctl list devices 的输出":
            "Impossible d'interpréter la sortie de simctl list devices",
        "无法解析 devicectl list devices 的输出":
            "Impossible d'interpréter la sortie de devicectl list devices",
        "读取项目信息失败": "Échec de la lecture des informations du projet",
        "读取构建设置失败": "Échec de la lecture des réglages de compilation",
        "读取模拟器列表失败": "Échec de la lecture de la liste des simulateurs",
        "读取真机列表失败": "Échec de la lecture de la liste des appareils",
        "该项目没有可用的 scheme（只有勾选 Shared 的 scheme 才会出现在列表中）":
            "Ce projet n'a aucun scheme utilisable (seuls les schemes marqués Shared apparaissent dans la liste)",
        "构建设置中没有 PRODUCT_BUNDLE_IDENTIFIER，该 scheme 可能不是可运行的 App target":
            "Les réglages de compilation ne contiennent pas PRODUCT_BUNDLE_IDENTIFIER — ce scheme n'est peut-être pas une cible App exécutable",
        "构建设置中缺少 BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME":
            "Les réglages de compilation ne contiennent pas BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME",
        "模拟器启动超时": "Délai dépassé en attendant le démarrage du simulateur",
        "启动模拟器失败：%@": "Échec du démarrage du simulateur : %@",
        "安装到模拟器失败：%@": "Échec de l'installation sur le simulateur : %@",
        "在模拟器上启动 App 失败：%@": "Échec du lancement de l'App sur le simulateur : %@",
        "安装到设备失败：%@": "Échec de l'installation sur l'appareil : %@",
        "在设备上启动 App 失败：%@": "Échec du lancement de l'App sur l'appareil : %@",
        "无法执行 %@：%@": "Impossible d'exécuter %@ : %@",
        "%@ 执行超时（%ds）": "%@ a dépassé le délai (%d s)",
        "%@ 退出码 %d": "%@ s'est terminé avec le code %d",
        "未知错误": "Erreur inconnue",

        // MARK: 工程与书签
        "%@ 不是 Xcode 工程": "%@ n'est pas un projet Xcode",
        "%@ 中找不到 .xcodeproj 或 .xcworkspace":
            "Aucun .xcodeproj ou .xcworkspace trouvé dans %@",
        "书签已失效，请重新选择项目":
            "Le signet n'est plus valide — sélectionnez à nouveau le projet",
        "无法为 %@ 创建书签": "Impossible de créer un signet pour %@",
        "找不到 %@": "%@ introuvable",

        // MARK: ErrorTranslator（可执行的下一步）
        "设备已锁屏，请解锁后重试": "L'appareil est verrouillé — déverrouillez-le et réessayez",
        "安装被拒绝：签名与设备不匹配，检查 provisioning profile 是否包含该设备":
            "Installation refusée : la signature ne correspond pas à l'appareil. Vérifiez que le provisioning profile inclut cet appareil",
        "provisioning profile 未包含任何设备，请在开发者后台添加该设备":
            "Le provisioning profile ne contient aucun appareil — ajoutez cet appareil dans le portail développeur",
        "缺少可用的 provisioning profile，请在 Xcode 中打开 Signing & Capabilities 配置自动签名":
            "Aucun provisioning profile utilisable — ouvrez Signing & Capabilities dans Xcode et activez la signature automatique",
        "签名失败：真机构建必须配置有效的签名证书与描述文件":
            "Échec de la signature : une compilation sur appareil exige un certificat de signature et un provisioning profile valides",
        "找不到签名证书，请在 Xcode 的账户设置中登录并下载证书":
            "Aucun certificat de signature — connectez-vous dans les réglages de comptes de Xcode et téléchargez vos certificats",
        "设备的开发者磁盘映像未挂载，通常重新插拔或重启设备可恢复":
            "L'image disque de développement de l'appareil n'est pas montée — rebranchez ou redémarrez l'appareil, cela suffit généralement",
        "设备未开启「开发者模式」，请在 设置 › 隐私与安全性 › 开发者模式 中打开":
            "Le mode développeur est désactivé sur l'appareil — activez-le dans Réglages › Confidentialité et sécurité › Mode développeur",
        "设备未连接或未信任本机，请检查连接后重试":
            "L'appareil n'est pas connecté ou ne fait pas confiance à ce Mac — vérifiez la connexion et réessayez",
        "该模拟器的数据已丢失，请在 Xcode › Devices and Simulators 中删除后重建":
            "Les données de ce simulateur ont disparu — supprimez-le et recréez-le dans Xcode › Devices and Simulators",
        "模拟器无法启动，尝试在 Simulator 中执行 Device › Erase All Content and Settings":
            "Le simulateur ne démarre pas — essayez Device › Erase All Content and Settings dans Simulator",
        "App 尚未安装到该设备，请重新运行一次":
            "L'App n'est pas encore installée sur cet appareil — relancez l'exécution",
        "该 scheme 未配置当前 action，请检查 scheme 的 Build/Run 设置":
            "Ce scheme n'est pas configuré pour l'action en cours — vérifiez ses réglages Build/Run",
        "工程中找不到该 scheme，可能已被重命名或未勾选 Shared":
            "Ce scheme est absent du projet — il a peut-être été renommé ou n'est pas marqué Shared",
        "找不到匹配的运行目标，设备可能已断开或模拟器已被删除":
            "Aucune destination correspondante — l'appareil est peut-être déconnecté ou le simulateur supprimé",
        "工程路径无效，文件可能已被移动或删除":
            "Le chemin du projet n'est pas valide — les fichiers ont peut-être été déplacés ou supprimés",
        "找不到构建产物，请重新构建": "Produit de compilation introuvable — recompilez",
    ]
}
