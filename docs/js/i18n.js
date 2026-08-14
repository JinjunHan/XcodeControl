/* ==========================================================================
   XcodeControl Landing Page i18n Dictionary & Manager
   ========================================================================== */

const i18nData = {
  zh: {
    page_title: "XcodeControl - 悬浮窗一键编译运行 Xcode 项目",
    page_meta_desc: "macOS 悬浮式极速构建工具。按下 ⌥⌘R 一键编译、安装并启动 Xcode 项目到模拟器与真机，无需切换窗口，专注心流。",
    
    // Header
    nav_features: "特性",
    nav_showcase: "体验",
    nav_specs: "技术规格",
    nav_faq: "常见问题",
    nav_download: "下载应用",

    // Hero
    hero_tag: "macOS 悬浮式极速构建工具",
    hero_title: "悬浮窗一键编译运行 Xcode 项目",
    hero_subtitle: "专为 AI 编程与 Vibe Coding 时代打造 —— 不用打开 Xcode，不用切换窗口，一键直达模拟器与真机。",
    hero_btn_download: "下载 macOS 版 DMG",
    hero_btn_github: "GitHub 仓库",
    hero_meta_sys: "macOS 14.0+",
    hero_meta_arch: "Apple Silicon & Intel 通用",
    hero_meta_sec: "Apple 官方公证",
    hero_meta_priv: "100% 本地 · 零遥测",
    chip_hotkey: "全局快捷键 ⌥⌘R",
    chip_status: "✓ 构建成功 (0.6s)",

    // Philosophy
    philosophy_tag: "为什么需要它",
    philosophy_title: "在 AI 编程时代，把注意力留在代码里",
    philosophy_desc: "当代码越来越多由 AI 编写，Xcode 几乎只剩下一个功能：Run。但每次运行都要切换窗口、等待响应，思维不断被打断。",
    trad_badge: "传统工作流",
    trad_headline: "反复切屏，割裂思路",
    trad_text: "在编辑器中改完代码 -> ⌘Tab 切到 Xcode -> 鼠标点击 Run -> ⌘Tab 切回编辑器 -> 遇到编译报错再去排查。",
    trad_item1: "每天几十次打断编程心流",
    trad_item2: "Xcode 界面庞大占用大半屏幕视线",
    trad_item3: "编译卡死时难以快速终止后台进程",
    xc_badge: "XcodeControl 悬浮工作流",
    xc_headline: "悬浮常驻，一键直达",
    xc_text: "主界面永远只有三个元素：设备、运行、停止。小窗常驻在屏幕角落，按下 ⌥⌘R，编译、安装、启动一步到位。",
    xc_item1: "注意力始终停留在写代码的窗口里",
    xc_item2: "次级信息默认收起，同一入口点两次即收起",
    xc_item3: "SIGINT 原子级优雅取消，毫秒级响应",

    // Features
    features_tag: "核心特性",
    features_title: "克制、敏捷、完全掌控",
    features_desc: "摒弃一切花哨功能，只为 Xcode 编译运行提供最高效的捷径。",
    feat1_title: "常驻悬浮窗",
    feat1_desc: "小窗轻巧浮在代码之上，选好项目和设备即可构建、安装、启动与停止，无需唤起 Xcode。",
    feat2_title: "全局快捷键",
    feat2_desc: "默认 ⌥⌘R，在任何编辑器或应用内按下都能运行，基于系统热键 API，无需辅助功能权限。",
    feat3_title: "iOS 与 macOS 双端",
    feat3_desc: "运行到 iOS 模拟器、已连接的 iPhone/iPad 真机，或直接运行 Mac App。",
    feat4_title: "多项目秒级管理",
    feat4_desc: "拖入 .xcodeproj 或 .xcworkspace 即可秒级添加，随时在多个工程之间无缝切换。",
    feat5_title: "清晰错误摘要",
    feat5_desc: "构建失败时提炼可执行的下一步建议，而不是原始报错；随时可一键展开完整构建日志。",
    feat6_title: "100% 隐私与本地",
    feat6_desc: "没有账号系统、没有分析与遥测，项目与构建输出完全留在你的 Mac 本地磁盘上。",

    // Showcase
    showcase_tag: "极简体验",
    showcase_title: "3 步开启轻快构建流",
    showcase_desc: "开箱即用，免配置复杂的命令行环境变量。",
    step1_title: "1. 下载并安装",
    step1_desc: "从 GitHub Releases 下载已通过 Apple 公证的 DMG 安装包，拖入“应用程序”文件夹启动。",
    step2_title: "2. 拖入项目与工作区",
    step2_desc: "打开或拖入 .xcodeproj / .xcworkspace 文件，自动解析 Shared Scheme 和可用设备。",
    step3_title: "3. 按下 ⌥⌘R 运行",
    step3_desc: "无需切换到 Xcode，在任何编辑器中按下快捷键，应用直接在目标设备上编译并启动！",
    hotkey_demo_tip: "👇 点击下方按键或在页面上按下 ⌥⌘R 试玩快捷键效果：",
    hotkey_demo_feedback: "🚀 快捷键触发：正在编译并在目标设备中启动...",

    // Specs & Security
    specs_tag: "规格与安全",
    specs_title: "纯粹、安全、透明",
    specs_desc: "以原生 macOS 工具链驱动，保障最高兼容性与执行效率。",
    specs_sys_label: "系统要求",
    specs_sys_val: "macOS 14.0 或更高版本",
    specs_xcode_label: "Xcode 环境",
    specs_xcode_val: "完整安装 Xcode (并通过 xcode-select 配置)",
    specs_arch_label: "架构支持",
    specs_arch_val: "Universal 2 (Apple Silicon M系列 & Intel x86_64)",
    specs_dist_label: "分发方式",
    specs_dist_val: "Developer ID 签名 + Apple Notarization 公证 DMG",
    sec_title: "安全与公证说明",
    sec1_h: "为什么不通过 Mac App Store 分发？",
    sec1_p: "XcodeControl 核心流程需要直接调用本机的 /usr/bin/xcrun、xcodebuild、simctl 和 devicectl。App Store 强制的沙盒机制会阻止这些系统进程调用，因此采用官方公证的独立分发模式。",
    sec2_h: "Apple 官方公证与 Gatekeeper 安全",
    sec2_p: "每个正式发布的 DMG 均使用 Apple 开发者证书签名并通过 Apple 服务器自动化公证（Stapled），首次启动不会出现“未知开发者”拦截。",
    sec3_h: "完全本地执行，无数据外传",
    sec3_p: "没有账户系统、没有广告和遥测。偏好设置与构建输出仅保存在本地标准 macOS 路径。",

    // FAQ
    faq_tag: "疑难解答",
    faq_title: "常见问题",
    faq_q1: "我需要一直保持 Xcode 处于打开状态吗？",
    faq_a1: "不需要。XcodeControl 底层直接调用 Apple 官方命令行工具链（xcodebuild / simctl / devicectl），即使彻底退出 Xcode 界面，也能正常编译、安装和启动应用。",
    faq_q2: "为什么需要完整的 Xcode 而不仅是 Command Line Tools？",
    faq_a2: "Command Line Tools 仅包含基础编译库，缺少 iOS 模拟器运行时、设备调试守护进程（devicectl）以及各平台的完整 SDK，因此必须安装完整 Xcode。",
    faq_q3: "快捷键是否支持自定义？",
    faq_a3: "支持。在设置窗口中可以自由更改全局运行快捷键，并可配置是否开机自启与悬浮窗初始位置。",
    faq_q4: "真机调试需要注意什么？",
    faq_a4: "真机需开启“开发者模式”并在 Xcode 中完成过至少一次信任证书配置，之后 XcodeControl 即可通过 devicectl 无缝部署运行。",

    // Footer
    footer_desc: "悬浮窗一键编译运行 Xcode 项目，献给每一位追求极致心流的 macOS 开发者。",
    footer_releases: "版本更新历史",
    footer_issues: "问题反馈 (Issues)",
    footer_privacy: "隐私政策",
    footer_copy: "© 2026 XcodeControl. All rights reserved."
  },
  en: {
    page_title: "XcodeControl - One-Click Build & Run for Xcode in a Floating HUD",
    page_meta_desc: "macOS floating quick-runner. Press ⌥⌘R to build, install, and launch Xcode projects to simulators and physical devices without switching windows.",

    // Header
    nav_features: "Features",
    nav_showcase: "Showcase",
    nav_specs: "Specs",
    nav_faq: "FAQ",
    nav_download: "Download",

    // Hero
    hero_tag: "macOS Floating Quick-Runner",
    hero_title: "One-Click Build & Run for Xcode",
    hero_subtitle: "Built for the AI & Vibe Coding era — build, install, and run without opening Xcode or switching windows.",
    hero_btn_download: "Download for macOS DMG",
    hero_btn_github: "GitHub Repo",
    hero_meta_sys: "macOS 14.0+",
    hero_meta_arch: "Universal (Apple Silicon & Intel)",
    hero_meta_sec: "Apple Notarized",
    hero_meta_priv: "100% Local · No Telemetry",
    chip_hotkey: "Global Hotkey ⌥⌘R",
    chip_status: "✓ Build Succeeded (0.6s)",

    // Philosophy
    philosophy_tag: "Why XcodeControl",
    philosophy_title: "Stay in Flow in the AI Coding Era",
    philosophy_desc: "When AI writes your code, Xcode only serves one purpose: Run. Constantly switching windows shatters developer flow dozens of times a day.",
    trad_badge: "Traditional Workflow",
    trad_headline: "Frequent Window Switching",
    trad_text: "Edit code in your editor -> ⌘Tab to Xcode -> Click Run -> ⌘Tab back -> Context lost when fixing compile issues.",
    trad_item1: "Dozens of context switches every single day",
    trad_item2: "Heavy Xcode IDE occupying entire screen real estate",
    trad_item3: "Slow and difficult build cancellation when stalled",
    xc_badge: "XcodeControl Workflow",
    xc_headline: "Floating HUD, Zero Friction",
    xc_text: "Always 3 core elements: Device, Run, Stop. Floating in your screen corner, ⌥⌘R builds, installs, and launches instantly.",
    xc_item1: "Keep focus strictly on your code and AI chats",
    xc_item2: "Minimal HUD footprint with smart auto-collapse",
    xc_item3: "Atomic SIGINT cancellation in sub-seconds",

    // Features
    features_tag: "Features",
    features_title: "Minimal, Agile, Fully in Control",
    features_desc: "Stripping away unnecessary fluff, purely focused on the fastest build and run loop.",
    feat1_title: "Floating HUD",
    feat1_desc: "Floats neatly above your editor. Control build, install, launch, and stop without bringing Xcode to foreground.",
    feat2_title: "Global Hotkey",
    feat2_desc: "Default ⌥⌘R works anywhere. Powered by native macOS hotkey APIs with zero accessibility prompts required.",
    feat3_title: "iOS & macOS Targets",
    feat3_desc: "Seamlessly supports iOS Simulators, connected physical iPhones/iPads, and native Mac Apps.",
    feat4_title: "Multi-Project Switcher",
    feat4_desc: "Drag and drop any .xcodeproj or .xcworkspace. Switch between active projects in seconds.",
    feat5_title: "Smart Error Digest",
    feat5_desc: "Presents actionable error summaries upon failure, with instant access to full build logs whenever needed.",
    feat6_title: "100% Local & Privacy",
    feat6_desc: "No accounts, no analytics, no telemetry. Your code and build artifacts stay strictly on your local Mac.",

    // Showcase
    showcase_tag: "Experience",
    showcase_title: "Get Started in 3 Simple Steps",
    showcase_desc: "Ready out of the box with zero complex environment configuration.",
    step1_title: "1. Download & Install",
    step1_desc: "Download the Apple-notarized DMG from GitHub Releases and drag XcodeControl into Applications.",
    step2_title: "2. Drag your Project",
    step2_desc: "Drag your .xcodeproj or .xcworkspace into Settings; Schemes and Devices auto-populate instantly.",
    step3_title: "3. Press ⌥⌘R to Run",
    step3_desc: "Stay in your code editor. Press ⌥⌘R and your app builds and launches on target immediately!",
    hotkey_demo_tip: "👇 Click keys below or press ⌥⌘R to test the trigger animation:",
    hotkey_demo_feedback: "🚀 Hotkey triggered: Building and launching on simulator...",

    // Specs & Security
    specs_tag: "Specs & Security",
    specs_title: "Pure, Secure, Transparent",
    specs_desc: "Driven by native macOS toolchains for maximum compatibility and speed.",
    specs_sys_label: "System Requirements",
    specs_sys_val: "macOS 14.0 or later",
    specs_xcode_label: "Xcode Toolchain",
    specs_xcode_val: "Full Xcode installed (configured via xcode-select)",
    specs_arch_label: "Architecture",
    specs_arch_val: "Universal 2 (Apple Silicon M-Series & Intel x86_64)",
    specs_dist_label: "Distribution",
    specs_dist_val: "Developer ID Signed + Apple Notarized DMG",
    sec_title: "Security & Notarization Notice",
    sec1_h: "Why not distributed via Mac App Store?",
    sec1_p: "XcodeControl needs to directly invoke /usr/bin/xcrun, xcodebuild, simctl, and devicectl. App Store mandatory sandbox blocks these toolchain processes, requiring notarized direct distribution.",
    sec2_h: "Apple Notarization & Gatekeeper",
    sec2_p: "Every official release is signed with an Apple Developer ID and notarized by Apple Gatekeeper, ensuring seamless installation without unknown developer warnings.",
    sec3_h: "100% Local Execution, Zero Telemetry",
    sec3_p: "No tracking SDKs, analytics, or background telemetry. Preferences and build outputs remain strictly on your Mac.",

    // FAQ
    faq_tag: "Troubleshooting",
    faq_title: "Frequently Asked Questions",
    faq_q1: "Do I need to keep Xcode open?",
    faq_a1: "No. XcodeControl operates completely through Apple's CLI toolchain (xcodebuild / simctl / devicectl), allowing you to build and run even when the Xcode IDE is fully closed.",
    faq_q2: "Why is a full Xcode installation required?",
    faq_a2: "Command Line Tools only contains basic compiler utilities, lacking iOS Simulator runtimes, devicectl, and complete iOS/macOS platform SDKs.",
    faq_q3: "Can I customize the global hotkey?",
    faq_a3: "Yes. You can customize the hotkey combination, launch at login, and initial window position directly in Settings.",
    faq_q4: "What's required for physical device debugging?",
    faq_a4: "Ensure Developer Mode is enabled on your device and trusted in Xcode once, after which XcodeControl deploys seamlessly via devicectl.",

    // Footer
    footer_desc: "One-click build & run for Xcode in a floating HUD. Crafted for flow-driven macOS developers.",
    footer_releases: "Release Changelog",
    footer_issues: "Issues & Feedback",
    footer_privacy: "Privacy Policy",
    footer_copy: "© 2026 XcodeControl. All rights reserved."
  }
};

class I18nManager {
  constructor() {
    this.currentLang = this.detectLanguage();
  }

  detectLanguage() {
    const saved = localStorage.getItem('xcodecontrol_lang');
    if (saved && (saved === 'zh' || saved === 'en')) {
      return saved;
    }
    const navLang = navigator.language || navigator.userLanguage || 'zh';
    return navLang.startsWith('zh') ? 'zh' : 'en';
  }

  setLanguage(lang) {
    if (lang !== 'zh' && lang !== 'en') return;
    this.currentLang = lang;
    localStorage.setItem('xcodecontrol_lang', lang);
    this.applyLanguage();
  }

  toggleLanguage() {
    const next = this.currentLang === 'zh' ? 'en' : 'zh';
    this.setLanguage(next);
  }

  applyLanguage() {
    const data = i18nData[this.currentLang];
    if (!data) return;

    document.documentElement.lang = this.currentLang === 'zh' ? 'zh-CN' : 'en';

    // Update document title
    if (data.page_title) {
      document.title = data.page_title;
    }

    // Update meta description
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc && data.page_meta_desc) {
      metaDesc.setAttribute('content', data.page_meta_desc);
    }

    // Update all elements with data-i18n
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      if (data[key]) {
        el.textContent = data[key];
      }
    });

    // Update elements with data-i18n-html
    document.querySelectorAll('[data-i18n-html]').forEach(el => {
      const key = el.getAttribute('data-i18n-html');
      if (data[key]) {
        el.innerHTML = data[key];
      }
    });

    // Update lang button text
    const langBtnText = document.getElementById('langBtnText');
    if (langBtnText) {
      langBtnText.textContent = this.currentLang === 'zh' ? 'English' : '简体中文';
    }

    // Trigger custom event for other scripts (e.g. release.js)
    window.dispatchEvent(new CustomEvent('languageChanged', { detail: { lang: this.currentLang } }));
  }

  getText(key) {
    const data = i18nData[this.currentLang];
    return (data && data[key]) ? data[key] : key;
  }
}

window.i18n = new I18nManager();
