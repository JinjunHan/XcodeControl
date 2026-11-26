//
//  L10nTable+ptBR.swift
//  XcodeControl
//

extension L10nTable {

    static let ptBR: [String: String] = [
        // MARK: 主界面三元素
        "运行": "Executar",
        "停止": "Parar",
        "选择设备": "Escolher Dispositivo",
        "清理后构建": "Limpar e compilar",
        "模块缓存缺失，正在清理并重试": "Cache de módulos ausente. Limpando e tentando novamente…",
        "运行（长按可清理后构建）": "Executar (segure para limpar antes)",
        "重新运行（长按可清理后构建）": "Executar Novamente (segure para limpar antes)",
        "取消构建": "Cancelar Compilação",
        "停止运行": "Parar Execução",
        "正在构建…": "Compilando…",

        // MARK: 运行状态
        "Building": "Compilando",
        "Installing": "Instalando",
        "Launching": "Iniciando",
        "Running": "Executando",
        "Failed": "Falhou",
        "准备": "Preparando",
        "解析依赖": "Resolvendo dependências",
        "编译 Swift": "Compilando Swift",
        "编译 C/ObjC": "Compilando C/ObjC",
        "编译资源": "Compilando recursos",
        "编译界面": "Compilando interface",
        "处理 Info.plist": "Processando Info.plist",
        "运行脚本": "Executando script",
        "链接": "Vinculando",
        "签名": "Assinando",
        "收尾": "Finalizando",
        "校验": "Validando",

        // MARK: 设备
        "模拟器": "Simuladores",
        "已连接设备": "Dispositivos conectados",
        "本机": "Este Mac",
        "我的 Mac": "Meu Mac",
        "已启动": "Iniciado",
        "已连接": "Conectado",
        "未连接": "Desconectado",
        "搜索设备": "Buscar dispositivos",
        "刷新设备列表": "Atualizar lista de dispositivos",
        "没有匹配的设备": "Nenhum dispositivo correspondente",
        "没有可用设备": "Nenhum dispositivo disponível",
        "未命名设备": "Dispositivo sem nome",

        // MARK: 项目
        "项目": "Projeto",
        "项目列表": "Projetos",
        "未选择项目": "Nenhum projeto selecionado",
        "尚未选择项目": "Nenhum projeto selecionado ainda",
        "添加项目…": "Adicionar Projeto…",
        "管理项目…": "Gerenciar projetos…",
        "选择项目…": "Escolher Projeto…",
        "在 Xcode 中打开": "Abrir no Xcode",
        "从列表移除": "Remover da Lista",
        "从列表中删除": "Remover da Lista",
        "路径已失效": "Caminho indisponível",
        "路径失效": "Caminho indisponível",
        "%@（路径已失效）": "%@ (caminho indisponível)",
        "设为当前项目": "Definir como Projeto Atual",
        "当前": "Atual",
        "选择或拖入 Xcode 项目": "Escolha ou arraste um projeto do Xcode",
        "拖入 .xcodeproj / .xcworkspace，或项目文件夹":
            "Arraste um .xcodeproj / .xcworkspace ou uma pasta de projeto",
        "正在解析…": "Analisando…",
        "未解析到 scheme": "Nenhum scheme encontrado",
        "解析失败，见悬浮窗": "Falha na análise — veja o painel",

        // MARK: Git
        "当前项目不在 Git 仓库中": "O projeto atual não está em um repositório Git",
        "无法读取当前 Git 分支": "Não foi possível ler a branch Git atual",
        "分支已不存在，请刷新列表后重试": "A branch não existe mais. Atualize a lista e tente novamente",
        "当前修改会被覆盖，请先提交或暂存后再切换分支":
            "As alterações atuais seriam sobrescritas. Faça commit ou stash antes de trocar de branch",
        "仓库有未解决的冲突，请先处理后再切换分支":
            "O repositório tem conflitos não resolvidos. Resolva-os antes de trocar de branch",
        "该分支正在另一个 Git worktree 中使用": "Esta branch está em uso em outro worktree do Git",
        "切换分支失败：%@": "Falha ao trocar de branch: %@",
        "切换 Git 分支": "Trocar branch do Git",
        "本地分支": "Branches locais",
        "正在读取分支…": "Carregando branches…",
        "没有本地分支": "Nenhuma branch local",
        "刷新分支列表": "Atualizar lista de branches",
        "同步 Worktree 项目": "Sincronizar projetos de worktree",
        "Git worktree 路径已失效，请先在终端清理该 worktree":
            "O caminho do worktree do Git é inválido. Limpe esse worktree no Terminal primeiro",
        "worktree": "worktree",
        "Git 操作详情：%@": "Detalhes da operação do Git: %@",
        "构建进行中，停止后可切换分支":
            "Há uma compilação em andamento. Interrompa-a antes de trocar de branch",

        // MARK: 日志
        "日志": "Log",
        "收起日志": "Recolher Log",
        "拷贝完整日志": "Copiar Log Completo",
        "拷贝错误信息": "Copiar Erro",
        "拷贝命令": "Copiar Comando",
        "查看完整日志": "Ver Log Completo",
        "过滤": "Filtrar",
        "自动滚动：开": "Rolagem automática: ativada",
        "自动滚动：关": "Rolagem automática: desativada",

        // MARK: 通用动作
        "设置": "Ajustes",
        "设置…": "Ajustes…",
        "关闭": "Fechar",
        "取消": "Cancelar",
        "完成": "Concluído",
        "清除": "Limpar",
        "清理": "Limpar",
        "清理…": "Limpar…",
        "清空": "Limpar Tudo",
        "添加": "Adicionar",
        "扫描": "Escanear",
        "扫描文件夹…": "Escanear Pasta…",
        "选择": "Escolher",
        "好的": "OK",
        "启用": "Ativar",
        "打开系统设置": "Abrir Ajustes do Sistema",
        "在 Finder 中显示": "Mostrar no Finder",
        "显示悬浮窗": "Mostrar Painel",
        "隐藏悬浮窗": "Ocultar Painel",
        "退出 XcodeControl": "Encerrar XcodeControl",
        "其他…": "Outro…",
        "自定义": "Personalizado",
        "自定义…": "Personalizado…",
        "默认": "Padrão",
        "未知": "Desconhecido",
        "秒": "s",
        "空格": "Espaço",
        "语言": "Idioma",
        "界面语言": "Idioma da Interface",
        "跟随系统": "Seguir o Sistema",

        // MARK: 设置页
        "通用": "Geral",
        "构建": "Compilação",
        "行为": "Comportamento",
        "位置": "Locais",
        "关于": "Sobre",
        "启动": "Inicialização",
        "浮窗": "Painel",
        "设备": "Dispositivos",
        "偏好设置": "Preferências",
        "开机自启动": "Abrir ao iniciar sessão",
        "启动时显示浮窗": "Mostrar o painel ao iniciar",
        "启动时打开设置": "Abrir os Ajustes ao iniciar",
        "显示 Git 分支": "Mostrar branch do Git",
        "失焦时降低不透明度": "Esmaecer quando inativo",
        "不透明度": "Opacidade",
        "重置窗口位置": "Redefinir Posição da Janela",
        "缓冲行数": "Linhas no buffer",
        "刷新间隔": "Intervalo de atualização",
        "开机自启动由系统「登录项」管理；首次开启可能需要你在系统设置里确认。":
            "A abertura no início de sessão é gerenciada pelos Itens de Início de Sessão do sistema; na primeira vez pode ser preciso confirmar nos Ajustes do Sistema.",
        "需要在系统设置中允许登录项。":
            "É preciso permitir o item de início de sessão nos Ajustes do Sistema.",
        "已申请开机自启，请在系统设置 › 通用 › 登录项中允许。":
            "A abertura no início de sessão foi solicitada. Permita em Ajustes do Sistema › Geral › Itens de Início de Sessão.",
        "超出后丢弃最旧的行。": "As linhas mais antigas são descartadas acima desse limite.",
        "构建期间自动暂停轮询。低于 2 秒无效。":
            "A consulta é pausada durante a compilação. Valores abaixo de 2 segundos não têm efeito.",

        // MARK: 设置页 · 构建
        "附着控制台输出": "Anexar saída do console",
        "附着后可在日志面板看到 App 的实时输出，代价是拿不到进程 PID。关闭则以分离方式启动。":
            "Anexar mostra a saída ao vivo do App no painel de log, ao custo de não obter o PID do processo. Desative para iniciar em modo desanexado.",
        "失败处理": "Tratamento de falhas",
        "构建失败时自动展开日志": "Expandir o log quando a compilação falhar",
        "失败后日志面板自动弹出，方便立刻看到错误。":
            "O painel de log abre automaticamente para você ver o erro na hora.",

        // MARK: 设置页 · 行为
        "构建成功时": "Em caso de sucesso",
        "构建失败时": "Em caso de falha",
        "发送通知": "Enviar notificação",
        "播放声音": "Reproduzir som",
        "浮窗隐藏时同样生效。": "Vale também quando o painel está oculto.",
        "全局快捷键": "Atalhos Globais",
        "已被占用": "Já está em uso",
        "需要通知权限": "Permissão de Notificação Necessária",
        "系统拒绝了通知权限。请在系统设置中为 XcodeControl 开启通知，然后再试。":
            "O sistema negou a permissão de notificação. Ative as notificações do XcodeControl nos Ajustes do Sistema e tente novamente.",
        "构建成功": "Compilação bem-sucedida",
        "构建失败": "Falha na compilação",

        // MARK: 设置页 · 位置
        "命令行工具": "Command Line Tools",
        "Derived Data 位置": "Local do Derived Data",
        "构建设置缓存": "Cache das configurações de compilação",
        "系统默认（xcode-select）": "Padrão do sistema (xcode-select)",
        "选择 Xcode.app": "Escolher Xcode.app",
        "选择 Derived Data 根目录": "Escolher a raiz do Derived Data",
        "选择自定义目录": "Escolher um diretório personalizado",
        "更改仅影响本应用的 DEVELOPER_DIR，不会改动系统的 xcode-select。":
            "Isso muda apenas o DEVELOPER_DIR deste app; o xcode-select do sistema não é alterado.",
        "清理 Derived Data？": "Limpar o Derived Data?",
        "清除构建设置缓存？": "Apagar o cache das configurações de compilação?",
        "回收": "Recuperar",
        "回收…": "Recuperar…",
        "%d 天未构建": "sem compilar há %d dias",
        "全部清除…": "Excluir tudo…",
        "清除全部 Derived Data？": "Excluir todos os Derived Data?",
        "Xcode 自己从不回收 Derived Data：工程移动或删除后，旧缓存会一直留在磁盘上。":
            "O Xcode nunca recupera os Derived Data sozinho: depois que um projeto é movido ou excluído, o cache antigo fica no disco para sempre.",
        "自动回收": "Recuperação automática",
        "回收已删除工程的缓存": "Recuperar caches de projetos excluídos",
        "回收长期未构建的缓存": "Recuperar caches sem compilação há muito tempo",
        "这一项删的是仍在使用的工程的缓存，代价是下次全量重编。构建成功后在后台执行，每天最多一次。":
            "Isto exclui caches de projetos ainda em uso, ao custo de uma recompilação completa na próxima vez. É executado em segundo plano após uma compilação bem-sucedida, no máximo uma vez por dia.",
        "超过 %d 天未构建": "Sem compilar há mais de %d dias",
        "依据缓存里记录的工程路径判定；路径已不存在即回收。判不出归属的目录会跳过。":
            "Avaliado pelo caminho do projeto registrado em cada cache; se não existir mais, é recuperado. Diretórios cuja origem não pode ser determinada são ignorados.",
        "自定义目录由本应用管理，可精确判定归属；不属于任何已托管工程的目录即回收。":
            "O diretório personalizado é gerenciado por este app, então a origem é exata; qualquer diretório que não pertença a um projeto gerenciado é recuperado.",
        "没有可回收的 Derived Data": "Nenhum Derived Data a recuperar",
        "所有缓存都属于仍在使用的工程。": "Todos os caches pertencem a projetos ainda em uso.",
        "回收 %d 份 Derived Data？": "Recuperar %d caches de Derived Data?",
        "共可释放 %@。此操作不可撤销。": "É possível liberar %@ no total. Esta ação não pode ser desfeita.",
        "已回收 %d 份无用的 Derived Data，释放 %@":
            "%d caches inúteis de Derived Data recuperados, liberando %@",
        "工程已不存在": "O projeto não existe mais",
        "…另有 %d 份": "…e mais %d",
        "启动后获取": "Lido ao iniciar",
        "路径": "Caminho",
        "版本": "Versão",
        "检查更新…": "Buscar Atualizações…",
        "反馈问题": "Relatar um Problema",
        "请通过 GitHub Issues 反馈问题，或在代码仓库提 PR。":
            "Relate problemas pelo GitHub Issues ou abra um PR no repositório.",

        // MARK: 设置页 · 项目
        "清空项目": "Limpar Projetos",
        "清空全部项目？": "Limpar todos os projetos?",
        "列表中的 %d 个项目都会移除，当前项目也会取消。":
            "Todos os %d projetos serão removidos e o projeto atual será desmarcado.",
        "还没有项目。拖入工程文件/文件夹，或用下方按钮添加。":
            "Nenhum projeto ainda. Arraste um arquivo ou pasta de projeto, ou adicione com o botão abaixo.",
        "拖拽行可调整顺序；也可拖入工程文件或文件夹添加。":
            "Arraste as linhas para reordenar; você também pode soltar arquivos ou pastas de projeto para adicioná-los.",
        "支持拖入 .xcodeproj / .xcworkspace，或包含它们的文件夹。":
            "Aceita arquivos .xcodeproj / .xcworkspace ou pastas que os contenham.",
        "选择 .xcodeproj / .xcworkspace，或包含它们的目录":
            "Escolha um .xcodeproj / .xcworkspace ou um diretório que contenha um",
        "选择 .xcodeproj 或 .xcworkspace": "Escolha um .xcodeproj ou .xcworkspace",
        "选择要扫描的根目录。同目录下若同时有 workspace 与 xcodeproj，只导入 workspace。":
            "Escolha um diretório raiz para escanear. Quando uma pasta tem workspace e xcodeproj, só o workspace é importado.",
        "正在扫描…": "Escaneando…",
        "已添加 %d 个项目。": "%d projetos adicionados.",
        "已通过拖放加入 %d 个项目。": "%d projetos adicionados por arrasto.",
        "扫描完成：新增 %d 个，已存在 %d 个。":
            "Escaneamento concluído: %d adicionados, %d já presentes.",
        "Worktree 同步完成：新增项目 %d 个，已存在 %d 个，未找到工程的 worktree %d 个。":
            "Sincronização de worktrees concluída: %d projetos adicionados, %d já presentes e %d worktrees sem projeto.",
        "没有新项目加入（可能已在列表中）。":
            "Nenhum projeto novo adicionado (talvez já estejam na lista).",
        "没有新项目加入（可能已在列表中或无法识别）。":
            "Nenhum projeto novo adicionado (talvez já estejam na lista ou não foram reconhecidos).",
        "未在该目录下发现可导入的工程。":
            "Nenhum projeto importável encontrado nesse diretório.",
        "未识别到 .xcodeproj / .xcworkspace": "Nenhum .xcodeproj / .xcworkspace reconhecido",

        // MARK: 环境错误
        "正在检查 Xcode 环境…": "Verificando o ambiente do Xcode…",
        "环境不可用": "Ambiente indisponível",
        "环境检查失败": "Falha na verificação do ambiente",
        "未能确定 Xcode 位置": "Não foi possível determinar o local do Xcode",
        "当前选中的是 Command Line Tools，不是完整的 Xcode":
            "As Command Line Tools estão selecionadas, e não um Xcode completo",
        "请选择要使用的 Xcode": "Escolha qual Xcode usar",
        "未找到完整的 Xcode": "Nenhuma instalação completa do Xcode foi encontrada",
        "前往设置": "Abrir Ajustes",
        "安装 Xcode": "Instalar Xcode",
        "xcodebuild 不可用": "xcodebuild indisponível",
        "Xcode %@ 尚未验证，若行为异常请反馈":
            "O Xcode %@ ainda não foi verificado — relate qualquer comportamento estranho",

        // MARK: 运行前置校验
        "还没有选择项目": "Nenhum projeto selecionado ainda",
        "还没有选择 scheme": "Nenhum scheme selecionado ainda",
        "还没有选择运行目标": "Nenhum destino de execução selecionado ainda",
        "已取消": "Cancelado",
        "App 启动后立即退出": "O App encerrou logo após ser iniciado",
        "App 已退出（退出码 %d）": "O App encerrou (código %d)",

        // MARK: 工具链错误
        "无法解析 xcodebuild -list 的输出":
            "Não foi possível analisar a saída de xcodebuild -list",
        "xcodebuild -list 输出中既没有 project 也没有 workspace":
            "A saída de xcodebuild -list não contém project nem workspace",
        "无法解析 -showBuildSettings 的输出":
            "Não foi possível analisar a saída de -showBuildSettings",
        "无法解析 simctl list devices 的输出":
            "Não foi possível analisar a saída de simctl list devices",
        "无法解析 devicectl list devices 的输出":
            "Não foi possível analisar a saída de devicectl list devices",
        "读取项目信息失败": "Falha ao ler as informações do projeto",
        "读取构建设置失败": "Falha ao ler as configurações de compilação",
        "读取模拟器列表失败": "Falha ao ler a lista de simuladores",
        "读取真机列表失败": "Falha ao ler a lista de dispositivos",
        "该项目没有可用的 scheme（只有勾选 Shared 的 scheme 才会出现在列表中）":
            "Este projeto não tem nenhum scheme utilizável (só schemes marcados como Shared aparecem na lista)",
        "构建设置中没有 PRODUCT_BUNDLE_IDENTIFIER，该 scheme 可能不是可运行的 App target":
            "As configurações de compilação não têm PRODUCT_BUNDLE_IDENTIFIER — este scheme pode não ser um target de App executável",
        "构建设置中缺少 BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME":
            "As configurações de compilação não têm BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME",
        "模拟器启动超时": "Tempo esgotado esperando o simulador iniciar",
        "启动模拟器失败：%@": "Falha ao iniciar o simulador: %@",
        "安装到模拟器失败：%@": "Falha ao instalar no simulador: %@",
        "在模拟器上启动 App 失败：%@": "Falha ao iniciar o App no simulador: %@",
        "安装到设备失败：%@": "Falha ao instalar no dispositivo: %@",
        "在设备上启动 App 失败：%@": "Falha ao iniciar o App no dispositivo: %@",
        "无法执行 %@：%@": "Não foi possível executar %@: %@",
        "%@ 执行超时（%ds）": "%@ atingiu o tempo limite (%d s)",
        "%@ 退出码 %d": "%@ encerrou com código %d",
        "未知错误": "Erro desconhecido",

        // MARK: 工程与书签
        "%@ 不是 Xcode 工程": "%@ não é um projeto do Xcode",
        "%@ 中找不到 .xcodeproj 或 .xcworkspace":
            "Nenhum .xcodeproj ou .xcworkspace encontrado em %@",
        "书签已失效，请重新选择项目":
            "O marcador expirou — escolha o projeto novamente",
        "无法为 %@ 创建书签": "Não foi possível criar um marcador para %@",
        "找不到 %@": "Não foi possível encontrar %@",

        // MARK: ErrorTranslator（可执行的下一步）
        "设备已锁屏，请解锁后重试":
            "O dispositivo está bloqueado — desbloqueie e tente novamente",
        "安装被拒绝：签名与设备不匹配，检查 provisioning profile 是否包含该设备":
            "Instalação recusada: a assinatura não corresponde ao dispositivo. Verifique se o provisioning profile inclui este dispositivo",
        "provisioning profile 未包含任何设备，请在开发者后台添加该设备":
            "O provisioning profile não contém nenhum dispositivo — adicione este dispositivo no portal do desenvolvedor",
        "缺少可用的 provisioning profile，请在 Xcode 中打开 Signing & Capabilities 配置自动签名":
            "Nenhum provisioning profile utilizável — abra Signing & Capabilities no Xcode e ative a assinatura automática",
        "签名失败：真机构建必须配置有效的签名证书与描述文件":
            "Falha na assinatura: compilações para dispositivo exigem um certificado de assinatura e um provisioning profile válidos",
        "找不到签名证书，请在 Xcode 的账户设置中登录并下载证书":
            "Nenhum certificado de assinatura encontrado — entre na sua conta nos ajustes do Xcode e baixe os certificados",
        "设备的开发者磁盘映像未挂载，通常重新插拔或重启设备可恢复":
            "A imagem de disco de desenvolvedor do dispositivo não está montada — reconectar ou reiniciar o dispositivo costuma resolver",
        "设备未开启「开发者模式」，请在 设置 › 隐私与安全性 › 开发者模式 中打开":
            "O Modo de Desenvolvedor está desativado no dispositivo — ative em Ajustes › Privacidade e Segurança › Modo de Desenvolvedor",
        "设备未连接或未信任本机，请检查连接后重试":
            "O dispositivo não está conectado ou não confia neste Mac — verifique a conexão e tente novamente",
        "该模拟器的数据已丢失，请在 Xcode › Devices and Simulators 中删除后重建":
            "Os dados deste simulador foram perdidos — apague e recrie o simulador em Xcode › Devices and Simulators",
        "模拟器无法启动，尝试在 Simulator 中执行 Device › Erase All Content and Settings":
            "O simulador não inicia — tente Device › Erase All Content and Settings no Simulator",
        "App 尚未安装到该设备，请重新运行一次":
            "O App ainda não está instalado nesse dispositivo — execute mais uma vez",
        "该 scheme 未配置当前 action，请检查 scheme 的 Build/Run 设置":
            "Este scheme não está configurado para a ação atual — verifique os ajustes de Build/Run do scheme",
        "工程中找不到该 scheme，可能已被重命名或未勾选 Shared":
            "O scheme não está no projeto — pode ter sido renomeado ou não estar marcado como Shared",
        "找不到匹配的运行目标，设备可能已断开或模拟器已被删除":
            "Nenhum destino correspondente — o dispositivo pode estar desconectado ou o simulador foi apagado",
        "工程路径无效，文件可能已被移动或删除":
            "O caminho do projeto é inválido — os arquivos podem ter sido movidos ou apagados",
        "找不到构建产物，请重新构建":
            "Produto de compilação não encontrado — compile novamente",
    ]
}
