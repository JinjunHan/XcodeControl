/* ==========================================================================
   XcodeControl Release & Version Fetcher
   Dynamically parses appcast.xml / GitHub Releases
   ========================================================================== */

class ReleaseManager {
  constructor() {
    this.version = "1.0.2";
    this.downloadUrl = "https://github.com/JinjunHan/XcodeControl/releases/download/v1.0.2/XcodeControl-1.0.2.dmg";
    this.fallbackUrl = "https://github.com/JinjunHan/XcodeControl/releases/latest";
    this.fileSize = "5.5 MB";
    this.pubDate = "";

    this.init();
  }

  async init() {
    await this.fetchFromAppcast();
    this.updateUI();

    // Re-render button texts on language toggle
    window.addEventListener("languageChanged", () => {
      this.updateUI();
    });
  }

  async fetchFromAppcast() {
    try {
      const response = await fetch("./appcast.xml", { cache: "no-cache" });
      if (!response.ok) throw new Error("Failed to load appcast.xml");

      const xmlText = await response.text();
      const parser = new DOMParser();
      const xmlDoc = parser.parseFromString(xmlText, "application/xml");

      const latestItem = xmlDoc.querySelector("channel > item");
      if (latestItem) {
        const titleEl = latestItem.querySelector("title");
        const versionEl = latestItem.getElementsByTagNameNS("http://www.andymatuschak.org/xml-namespaces/sparkle", "shortVersionString")[0] ||
                          latestItem.querySelector("shortVersionString");
        const enclosureEl = latestItem.querySelector("enclosure");

        if (versionEl && versionEl.textContent) {
          this.version = versionEl.textContent.trim();
        } else if (titleEl && titleEl.textContent) {
          this.version = titleEl.textContent.trim().replace(/^v/, '');
        }

        if (enclosureEl) {
          const url = enclosureEl.getAttribute("url");
          const length = parseInt(enclosureEl.getAttribute("length"), 10);
          if (url) this.downloadUrl = url;
          if (!isNaN(length) && length > 0) {
            this.fileSize = (length / (1024 * 1024)).toFixed(1) + " MB";
          }
        }
      }
    } catch (e) {
      console.log("Appcast local fetch note (using default release config):", e.message);
    }
  }

  updateUI() {
    const isZh = (window.i18n && window.i18n.currentLang === "zh");
    const formattedTag = this.version.startsWith("v") ? this.version : `v${this.version}`;

    // Update hero main CTA
    const mainBtn = document.getElementById("heroDownloadBtn");
    if (mainBtn) {
      mainBtn.href = this.downloadUrl;
      const baseLabel = isZh ? "下载 macOS 版 DMG" : "Download for macOS DMG";
      mainBtn.innerHTML = `
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
          <polyline points="7 10 12 15 17 10"></polyline>
          <line x1="12" y1="15" x2="12" y2="3"></line>
        </svg>
        <span>${baseLabel} <small style="opacity:0.85; font-size:0.85em; font-weight:400;">(${formattedTag} · ${this.fileSize})</small></span>
      `;
    }

    // Update nav CTA
    const navBtn = document.getElementById("navDownloadBtn");
    if (navBtn) {
      navBtn.href = this.downloadUrl;
    }

    // Update all general version placeholders
    document.querySelectorAll(".dynamic-version-tag").forEach(el => {
      el.textContent = formattedTag;
    });

    document.querySelectorAll(".dynamic-size-tag").forEach(el => {
      el.textContent = this.fileSize;
    });
  }
}

window.releaseManager = new ReleaseManager();
