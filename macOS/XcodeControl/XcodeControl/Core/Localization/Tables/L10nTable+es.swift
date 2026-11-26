//
//  L10nTable+es.swift
//  XcodeControl
//

extension L10nTable {

    static let es: [String: String] = [
        // MARK: 主界面三元素
        "运行": "Ejecutar",
        "停止": "Detener",
        "选择设备": "Elegir dispositivo",
        "清理后构建": "Limpiar y compilar",
        "模块缓存缺失，正在清理并重试": "Falta la caché de módulos. Limpiando y reintentando…",
        "运行（长按可清理后构建）": "Ejecutar (mantener pulsado para limpiar antes)",
        "重新运行（长按可清理后构建）":
            "Volver a ejecutar (mantener pulsado para limpiar antes)",
        "取消构建": "Cancelar compilación",
        "停止运行": "Detener ejecución",
        "正在构建…": "Compilando…",

        // MARK: 运行状态
        "Building": "Compilando",
        "Installing": "Instalando",
        "Launching": "Iniciando",
        "Running": "Ejecutando",
        "Failed": "Error",
        "准备": "Preparando",
        "解析依赖": "Resolviendo dependencias",
        "编译 Swift": "Compilando Swift",
        "编译 C/ObjC": "Compilando C/ObjC",
        "编译资源": "Compilando recursos",
        "编译界面": "Compilando la interfaz",
        "处理 Info.plist": "Procesando Info.plist",
        "运行脚本": "Ejecutando script",
        "链接": "Enlazando",
        "签名": "Firmando",
        "收尾": "Finalizando",
        "校验": "Validando",

        // MARK: 设备
        "模拟器": "Simuladores",
        "已连接设备": "Dispositivos conectados",
        "本机": "Este Mac",
        "我的 Mac": "Mi Mac",
        "已启动": "Iniciado",
        "已连接": "Conectado",
        "未连接": "Desconectado",
        "搜索设备": "Buscar dispositivos",
        "刷新设备列表": "Actualizar la lista de dispositivos",
        "没有匹配的设备": "No hay dispositivos coincidentes",
        "没有可用设备": "No hay dispositivos disponibles",
        "未命名设备": "Dispositivo sin nombre",

        // MARK: 项目
        "项目": "Proyecto",
        "项目列表": "Proyectos",
        "未选择项目": "Ningún proyecto seleccionado",
        "尚未选择项目": "Aún no hay ningún proyecto seleccionado",
        "添加项目…": "Añadir proyecto…",
        "管理项目…": "Gestionar proyectos…",
        "选择项目…": "Elegir proyecto…",
        "在 Xcode 中打开": "Abrir en Xcode",
        "从列表移除": "Quitar de la lista",
        "从列表中删除": "Quitar de la lista",
        "路径已失效": "Ruta no disponible",
        "路径失效": "Ruta no disponible",
        "%@（路径已失效）": "%@ (ruta no disponible)",
        "设为当前项目": "Definir como proyecto actual",
        "当前": "Actual",
        "选择或拖入 Xcode 项目": "Elige o arrastra un proyecto de Xcode",
        "拖入 .xcodeproj / .xcworkspace，或项目文件夹":
            "Arrastra un .xcodeproj / .xcworkspace o una carpeta de proyecto",
        "正在解析…": "Analizando…",
        "未解析到 scheme": "No se encontró ningún scheme",
        "解析失败，见悬浮窗": "Error al analizar; consulta el panel",

        // MARK: Git
        "当前项目不在 Git 仓库中": "El proyecto actual no está en un repositorio Git",
        "无法读取当前 Git 分支": "No se puede leer la rama Git actual",
        "分支已不存在，请刷新列表后重试": "La rama ya no existe. Actualiza la lista y vuelve a intentarlo",
        "当前修改会被覆盖，请先提交或暂存后再切换分支":
            "Los cambios actuales se sobrescribirían. Haz commit o stash antes de cambiar de rama",
        "仓库有未解决的冲突，请先处理后再切换分支":
            "El repositorio tiene conflictos sin resolver. Resuélvelos antes de cambiar de rama",
        "该分支正在另一个 Git worktree 中使用": "Esta rama se está usando en otro worktree de Git",
        "切换分支失败：%@": "No se pudo cambiar de rama: %@",
        "切换 Git 分支": "Cambiar rama de Git",
        "本地分支": "Ramas locales",
        "正在读取分支…": "Cargando ramas…",
        "没有本地分支": "No hay ramas locales",
        "刷新分支列表": "Actualizar lista de ramas",
        "同步 Worktree 项目": "Sincronizar proyectos de worktree",
        "Git worktree 路径已失效，请先在终端清理该 worktree":
            "La ruta del worktree de Git no es válida. Limpia primero ese worktree en Terminal",
        "worktree": "worktree",
        "Git 操作详情：%@": "Detalles de la operación Git: %@",
        "构建进行中，停止后可切换分支":
            "Hay una compilación en curso. Detenla antes de cambiar de rama",

        // MARK: 日志
        "日志": "Registro",
        "收起日志": "Contraer el registro",
        "拷贝完整日志": "Copiar el registro completo",
        "拷贝错误信息": "Copiar el error",
        "拷贝命令": "Copiar el comando",
        "查看完整日志": "Ver el registro completo",
        "过滤": "Filtrar",
        "自动滚动：开": "Autodesplazamiento: activado",
        "自动滚动：关": "Autodesplazamiento: desactivado",

        // MARK: 通用动作
        "设置": "Ajustes",
        "设置…": "Ajustes…",
        "关闭": "Cerrar",
        "取消": "Cancelar",
        "完成": "Listo",
        "清除": "Borrar",
        "清理": "Limpiar",
        "清理…": "Limpiar…",
        "清空": "Borrar todo",
        "添加": "Añadir",
        "扫描": "Escanear",
        "扫描文件夹…": "Escanear carpeta…",
        "选择": "Elegir",
        "好的": "Aceptar",
        "启用": "Activar",
        "打开系统设置": "Abrir Ajustes del Sistema",
        "在 Finder 中显示": "Mostrar en el Finder",
        "显示悬浮窗": "Mostrar el panel",
        "隐藏悬浮窗": "Ocultar el panel",
        "退出 XcodeControl": "Salir de XcodeControl",
        "其他…": "Otro…",
        "自定义": "Personalizado",
        "自定义…": "Personalizado…",
        "默认": "Predeterminado",
        "未知": "Desconocido",
        "秒": "s",
        "空格": "Espacio",
        "语言": "Idioma",
        "界面语言": "Idioma de la interfaz",
        "跟随系统": "Igual que el sistema",

        // MARK: 设置页
        "通用": "General",
        "构建": "Compilación",
        "行为": "Comportamiento",
        "位置": "Ubicaciones",
        "关于": "Acerca de",
        "启动": "Inicio",
        "浮窗": "Panel",
        "设备": "Dispositivos",
        "偏好设置": "Preferencias",
        "开机自启动": "Abrir al iniciar sesión",
        "启动时显示浮窗": "Mostrar el panel al abrir",
        "启动时打开设置": "Abrir Ajustes al arrancar",
        "显示 Git 分支": "Mostrar rama de Git",
        "失焦时降低不透明度": "Atenuar cuando esté inactivo",
        "不透明度": "Opacidad",
        "重置窗口位置": "Restablecer la posición de la ventana",
        "缓冲行数": "Líneas del búfer",
        "刷新间隔": "Intervalo de actualización",
        "开机自启动由系统「登录项」管理；首次开启可能需要你在系统设置里确认。":
            "El arranque automático lo gestionan los ítems de inicio de sesión del sistema; la primera vez que lo actives puede que tengas que confirmarlo en Ajustes del Sistema.",
        "需要在系统设置中允许登录项。":
            "Tienes que permitir el ítem de inicio de sesión en Ajustes del Sistema.",
        "已申请开机自启，请在系统设置 › 通用 › 登录项中允许。":
            "Se solicitó el arranque automático. Permítelo en Ajustes del Sistema › General › Ítems de inicio de sesión.",
        "超出后丢弃最旧的行。": "Al superar este límite se descartan las líneas más antiguas.",
        "构建期间自动暂停轮询。低于 2 秒无效。":
            "El sondeo se pausa durante la compilación. Los valores por debajo de 2 segundos no tienen efecto.",

        // MARK: 设置页 · 构建
        "附着控制台输出": "Adjuntar la salida de la consola",
        "附着后可在日志面板看到 App 的实时输出，代价是拿不到进程 PID。关闭则以分离方式启动。":
            "Al adjuntarla verás la salida en vivo de la App en el panel de registro, a costa de no obtener el PID del proceso. Desactívala para iniciar de forma separada.",
        "失败处理": "En caso de fallo",
        "构建失败时自动展开日志": "Expandir el registro cuando falle la compilación",
        "失败后日志面板自动弹出，方便立刻看到错误。":
            "El panel de registro se abre solo para que veas el error de inmediato.",

        // MARK: 设置页 · 行为
        "构建成功时": "Si la compilación es correcta",
        "构建失败时": "Si la compilación falla",
        "发送通知": "Enviar una notificación",
        "播放声音": "Reproducir un sonido",
        "浮窗隐藏时同样生效。": "También se aplica cuando el panel está oculto.",
        "全局快捷键": "Atajos globales",
        "已被占用": "Ya está en uso",
        "需要通知权限": "Se necesita permiso de notificaciones",
        "系统拒绝了通知权限。请在系统设置中为 XcodeControl 开启通知，然后再试。":
            "El sistema denegó el permiso de notificaciones. Activa las notificaciones de XcodeControl en Ajustes del Sistema y vuelve a intentarlo.",
        "构建成功": "Compilación correcta",
        "构建失败": "Error de compilación",

        // MARK: 设置页 · 位置
        "命令行工具": "Command Line Tools",
        "Derived Data 位置": "Ubicación de Derived Data",
        "构建设置缓存": "Caché de ajustes de compilación",
        "系统默认（xcode-select）": "Predeterminado del sistema (xcode-select)",
        "选择 Xcode.app": "Elegir Xcode.app",
        "选择 Derived Data 根目录": "Elegir la raíz de Derived Data",
        "选择自定义目录": "Elegir un directorio personalizado",
        "更改仅影响本应用的 DEVELOPER_DIR，不会改动系统的 xcode-select。":
            "El cambio solo afecta al DEVELOPER_DIR de esta app; no modifica el xcode-select del sistema.",
        "清理 Derived Data？": "¿Limpiar Derived Data?",
        "清除构建设置缓存？": "¿Borrar la caché de ajustes de compilación?",
        "回收": "Depurar",
        "回收…": "Depurar…",
        "%d 天未构建": "sin compilar desde hace %d días",
        "全部清除…": "Eliminar todo…",
        "清除全部 Derived Data？": "¿Eliminar todos los Derived Data?",
        "Xcode 自己从不回收 Derived Data：工程移动或删除后，旧缓存会一直留在磁盘上。":
            "Xcode nunca depura los Derived Data por su cuenta: tras mover o eliminar un proyecto, su caché permanece en el disco para siempre.",
        "自动回收": "Depuración automática",
        "回收已删除工程的缓存": "Depurar cachés de proyectos eliminados",
        "回收长期未构建的缓存": "Depurar cachés sin compilar desde hace tiempo",
        "这一项删的是仍在使用的工程的缓存，代价是下次全量重编。构建成功后在后台执行，每天最多一次。":
            "Esto elimina cachés de proyectos aún en uso, a costa de una recompilación completa la próxima vez. Se ejecuta en segundo plano tras una compilación correcta, como máximo una vez al día.",
        "超过 %d 天未构建": "Sin compilar desde hace más de %d días",
        "依据缓存里记录的工程路径判定；路径已不存在即回收。判不出归属的目录会跳过。":
            "Se juzga por la ruta del proyecto registrada en cada caché; si ya no existe, se depura. Se omiten los directorios cuya pertenencia no puede determinarse.",
        "自定义目录由本应用管理，可精确判定归属；不属于任何已托管工程的目录即回收。":
            "Esta app gestiona el directorio personalizado, así que la pertenencia es exacta; se depura cualquier directorio que no pertenezca a un proyecto gestionado.",
        "没有可回收的 Derived Data": "No hay Derived Data que depurar",
        "所有缓存都属于仍在使用的工程。": "Todas las cachés pertenecen a proyectos aún en uso.",
        "回收 %d 份 Derived Data？": "¿Depurar %d cachés de Derived Data?",
        "共可释放 %@。此操作不可撤销。": "Se pueden liberar %@ en total. Esta acción no se puede deshacer.",
        "已回收 %d 份无用的 Derived Data，释放 %@":
            "Se depuraron %d cachés inútiles de Derived Data, liberando %@",
        "工程已不存在": "El proyecto ya no existe",
        "…另有 %d 份": "…y %d más",
        "启动后获取": "Se lee al arrancar",
        "路径": "Ruta",
        "版本": "Versión",
        "检查更新…": "Buscar actualizaciones…",
        "反馈问题": "Informar de un problema",
        "请通过 GitHub Issues 反馈问题，或在代码仓库提 PR。":
            "Informa de los problemas en GitHub Issues o abre un PR en el repositorio.",

        // MARK: 设置页 · 项目
        "清空项目": "Borrar los proyectos",
        "清空全部项目？": "¿Borrar todos los proyectos?",
        "列表中的 %d 个项目都会移除，当前项目也会取消。":
            "Se quitarán los %d proyectos de la lista y se deseleccionará el proyecto actual.",
        "还没有项目。拖入工程文件/文件夹，或用下方按钮添加。":
            "Aún no hay proyectos. Arrastra un archivo o una carpeta de proyecto, o añádelo con el botón de abajo.",
        "拖拽行可调整顺序；也可拖入工程文件或文件夹添加。":
            "Arrastra las filas para reordenarlas; también puedes soltar archivos o carpetas de proyecto para añadirlos.",
        "支持拖入 .xcodeproj / .xcworkspace，或包含它们的文件夹。":
            "Admite archivos .xcodeproj / .xcworkspace, o carpetas que los contengan.",
        "选择 .xcodeproj / .xcworkspace，或包含它们的目录":
            "Elige un .xcodeproj / .xcworkspace, o un directorio que lo contenga",
        "选择 .xcodeproj 或 .xcworkspace": "Elige un .xcodeproj o un .xcworkspace",
        "选择要扫描的根目录。同目录下若同时有 workspace 与 xcodeproj，只导入 workspace。":
            "Elige el directorio raíz que se escaneará. Si una carpeta contiene a la vez un workspace y un xcodeproj, solo se importa el workspace.",
        "正在扫描…": "Escaneando…",
        "已添加 %d 个项目。": "Se añadieron %d proyectos.",
        "已通过拖放加入 %d 个项目。": "Se añadieron %d proyectos al soltarlos.",
        "扫描完成：新增 %d 个，已存在 %d 个。":
            "Escaneo completado: %d añadidos, %d ya existían.",
        "Worktree 同步完成：新增项目 %d 个，已存在 %d 个，未找到工程的 worktree %d 个。":
            "Sincronización de worktrees completada: %d proyectos añadidos, %d ya existentes y %d worktrees sin proyecto.",
        "没有新项目加入（可能已在列表中）。":
            "No se añadió ningún proyecto nuevo (puede que ya estén en la lista).",
        "没有新项目加入（可能已在列表中或无法识别）。":
            "No se añadió ningún proyecto nuevo (puede que ya estén en la lista o que no se reconocieran).",
        "未在该目录下发现可导入的工程。":
            "No se encontró ningún proyecto importable en ese directorio.",
        "未识别到 .xcodeproj / .xcworkspace": "No se reconoció ningún .xcodeproj / .xcworkspace",

        // MARK: 环境错误
        "正在检查 Xcode 环境…": "Comprobando el entorno de Xcode…",
        "环境不可用": "Entorno no disponible",
        "环境检查失败": "Error al comprobar el entorno",
        "未能确定 Xcode 位置": "No se pudo determinar la ubicación de Xcode",
        "当前选中的是 Command Line Tools，不是完整的 Xcode":
            "Están seleccionadas las Command Line Tools, no un Xcode completo",
        "请选择要使用的 Xcode": "Elige qué Xcode usar",
        "未找到完整的 Xcode": "No se encontró una instalación completa de Xcode",
        "前往设置": "Abrir Ajustes",
        "安装 Xcode": "Instalar Xcode",
        "xcodebuild 不可用": "xcodebuild no está disponible",
        "Xcode %@ 尚未验证，若行为异常请反馈":
            "Xcode %@ aún no se ha verificado; informa de cualquier comportamiento extraño",

        // MARK: 运行前置校验
        "还没有选择项目": "Aún no hay ningún proyecto seleccionado",
        "还没有选择 scheme": "Aún no hay ningún scheme seleccionado",
        "还没有选择运行目标": "Aún no hay ningún destino de ejecución seleccionado",
        "已取消": "Cancelado",
        "App 启动后立即退出": "La App se cerró justo después de iniciarse",
        "App 已退出（退出码 %d）": "La App se cerró (código %d)",

        // MARK: 工具链错误
        "无法解析 xcodebuild -list 的输出": "No se pudo analizar la salida de xcodebuild -list",
        "xcodebuild -list 输出中既没有 project 也没有 workspace":
            "La salida de xcodebuild -list no contiene ni project ni workspace",
        "无法解析 -showBuildSettings 的输出":
            "No se pudo analizar la salida de -showBuildSettings",
        "无法解析 simctl list devices 的输出":
            "No se pudo analizar la salida de simctl list devices",
        "无法解析 devicectl list devices 的输出":
            "No se pudo analizar la salida de devicectl list devices",
        "读取项目信息失败": "Error al leer la información del proyecto",
        "读取构建设置失败": "Error al leer los ajustes de compilación",
        "读取模拟器列表失败": "Error al leer la lista de simuladores",
        "读取真机列表失败": "Error al leer la lista de dispositivos físicos",
        "该项目没有可用的 scheme（只有勾选 Shared 的 scheme 才会出现在列表中）":
            "Este proyecto no tiene ningún scheme utilizable (solo aparecen en la lista los schemes marcados como Shared)",
        "构建设置中没有 PRODUCT_BUNDLE_IDENTIFIER，该 scheme 可能不是可运行的 App target":
            "Los ajustes de compilación no tienen PRODUCT_BUNDLE_IDENTIFIER; puede que este scheme no sea un target de App ejecutable",
        "构建设置中缺少 BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME":
            "Faltan BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME en los ajustes de compilación",
        "模拟器启动超时": "Se agotó el tiempo de espera al arrancar el simulador",
        "启动模拟器失败：%@": "No se pudo arrancar el simulador: %@",
        "安装到模拟器失败：%@": "No se pudo instalar en el simulador: %@",
        "在模拟器上启动 App 失败：%@": "No se pudo iniciar la App en el simulador: %@",
        "安装到设备失败：%@": "No se pudo instalar en el dispositivo: %@",
        "在设备上启动 App 失败：%@": "No se pudo iniciar la App en el dispositivo: %@",
        "无法执行 %@：%@": "No se pudo ejecutar %@: %@",
        "%@ 执行超时（%ds）": "%@ agotó el tiempo de espera (%d s)",
        "%@ 退出码 %d": "%@ terminó con el código %d",
        "未知错误": "Error desconocido",

        // MARK: 工程与书签
        "%@ 不是 Xcode 工程": "%@ no es un proyecto de Xcode",
        "%@ 中找不到 .xcodeproj 或 .xcworkspace":
            "No se encontró ningún .xcodeproj o .xcworkspace en %@",
        "书签已失效，请重新选择项目":
            "El marcador ya no es válido; vuelve a elegir el proyecto",
        "无法为 %@ 创建书签": "No se pudo crear un marcador para %@",
        "找不到 %@": "No se encontró %@",

        // MARK: ErrorTranslator（可执行的下一步）
        "设备已锁屏，请解锁后重试":
            "El dispositivo está bloqueado; desbloquéalo y vuelve a intentarlo",
        "安装被拒绝：签名与设备不匹配，检查 provisioning profile 是否包含该设备":
            "Instalación rechazada: la firma no coincide con el dispositivo. Comprueba que el provisioning profile incluya este dispositivo",
        "provisioning profile 未包含任何设备，请在开发者后台添加该设备":
            "El provisioning profile no incluye ningún dispositivo; añade este dispositivo en el portal de desarrolladores",
        "缺少可用的 provisioning profile，请在 Xcode 中打开 Signing & Capabilities 配置自动签名":
            "No hay ningún provisioning profile utilizable; abre Signing & Capabilities en Xcode y activa la firma automática",
        "签名失败：真机构建必须配置有效的签名证书与描述文件":
            "Error de firma: las compilaciones para dispositivo físico necesitan un certificado de firma y un provisioning profile válidos",
        "找不到签名证书，请在 Xcode 的账户设置中登录并下载证书":
            "No se encontró ningún certificado de firma; inicia sesión en los ajustes de cuentas de Xcode y descarga tus certificados",
        "设备的开发者磁盘映像未挂载，通常重新插拔或重启设备可恢复":
            "La imagen de disco de desarrollador del dispositivo no está montada; volver a conectarlo o reiniciarlo suele solucionarlo",
        "设备未开启「开发者模式」，请在 设置 › 隐私与安全性 › 开发者模式 中打开":
            "El modo de desarrollador está desactivado en el dispositivo; actívalo en Ajustes › Privacidad y seguridad › Modo Desarrollador",
        "设备未连接或未信任本机，请检查连接后重试":
            "El dispositivo no está conectado o no confía en este Mac; comprueba la conexión y vuelve a intentarlo",
        "该模拟器的数据已丢失，请在 Xcode › Devices and Simulators 中删除后重建":
            "Se perdieron los datos de este simulador; elimínalo y vuelve a crearlo en Xcode › Devices and Simulators",
        "模拟器无法启动，尝试在 Simulator 中执行 Device › Erase All Content and Settings":
            "El simulador no arranca; prueba con Device › Erase All Content and Settings en Simulator",
        "App 尚未安装到该设备，请重新运行一次":
            "La App aún no está instalada en ese dispositivo; ejecútala una vez más",
        "该 scheme 未配置当前 action，请检查 scheme 的 Build/Run 设置":
            "Este scheme no está configurado para la acción actual; revisa sus ajustes de Build/Run",
        "工程中找不到该 scheme，可能已被重命名或未勾选 Shared":
            "El scheme no está en el proyecto; puede que se haya renombrado o que no esté marcado como Shared",
        "找不到匹配的运行目标，设备可能已断开或模拟器已被删除":
            "No hay ningún destino coincidente; puede que el dispositivo se haya desconectado o que el simulador se haya eliminado",
        "工程路径无效，文件可能已被移动或删除":
            "La ruta del proyecto no es válida; puede que los archivos se hayan movido o eliminado",
        "找不到构建产物，请重新构建":
            "No se encontró el producto de compilación; vuelve a compilar",
    ]
}
