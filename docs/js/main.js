/* ==========================================================================
   XcodeControl Main Interactions & Animations
   ========================================================================== */

document.addEventListener("DOMContentLoaded", () => {
  // 1. Initialize i18n
  if (window.i18n) {
    window.i18n.applyLanguage();
  }

  // 2. Language Toggle Button
  const langToggleBtn = document.getElementById("langToggleBtn");
  if (langToggleBtn && window.i18n) {
    langToggleBtn.addEventListener("click", () => {
      window.i18n.toggleLanguage();
    });
  }

  // 3. Navbar scroll blur & shadow
  const header = document.getElementById("siteHeader");
  const handleScroll = () => {
    if (window.scrollY > 20) {
      header?.classList.add("scrolled");
    } else {
      header?.classList.remove("scrolled");
    }
  };
  window.addEventListener("scroll", handleScroll, { passive: true });
  handleScroll();

  // 4. FAQ Accordion Interaction
  const faqItems = document.querySelectorAll(".faq-item");
  faqItems.forEach(item => {
    const questionBtn = item.querySelector(".faq-question");
    const answer = item.querySelector(".faq-answer");

    if (questionBtn && answer) {
      questionBtn.addEventListener("click", () => {
        const isActive = item.classList.contains("active");

        // Close other items
        faqItems.forEach(otherItem => {
          if (otherItem !== item) {
            otherItem.classList.remove("active");
            const otherAnswer = otherItem.querySelector(".faq-answer");
            if (otherAnswer) otherAnswer.style.maxHeight = null;
          }
        });

        // Toggle current item
        if (!isActive) {
          item.classList.add("active");
          answer.style.maxHeight = answer.scrollHeight + 40 + "px";
        } else {
          item.classList.remove("active");
          answer.style.maxHeight = null;
        }
      });
    }
  });

  // 5. Interactive Hotkey Demo Simulation
  const hotkeyBox = document.getElementById("hotkeyInteractiveKeys");
  const hotkeyFeedback = document.getElementById("hotkeyFeedback");

  const triggerHotkeyDemo = () => {
    if (!hotkeyBox || !hotkeyFeedback) return;

    // Visual button press
    hotkeyBox.style.transform = "scale(0.92)";
    setTimeout(() => {
      hotkeyBox.style.transform = "scale(1)";
    }, 150);

    const feedbackMsg = window.i18n ? window.i18n.getText("hotkey_demo_feedback") : "🚀 快捷键触发：正在编译并在目标设备中启动...";
    hotkeyFeedback.textContent = feedbackMsg;
    hotkeyFeedback.style.opacity = "1";

    setTimeout(() => {
      hotkeyFeedback.style.opacity = "0.7";
    }, 3000);
  };

  if (hotkeyBox) {
    hotkeyBox.addEventListener("click", triggerHotkeyDemo);
  }

  // Listen to physical ⌥⌘R key combination on the page
  window.addEventListener("keydown", (e) => {
    // Option (altKey) + Command (metaKey) + R (code 'KeyR' or key 'r')
    if (e.altKey && e.metaKey && (e.key === 'r' || e.key === 'R' || e.code === 'KeyR')) {
      e.preventDefault();
      triggerHotkeyDemo();
    }
  });

  // 6. Smooth Scroll for internal navigation links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener("click", function (e) {
      const targetId = this.getAttribute("href");
      if (targetId && targetId !== "#") {
        const targetElement = document.querySelector(targetId);
        if (targetElement) {
          e.preventDefault();
          const offsetTop = targetElement.getBoundingClientRect().top + window.pageYOffset - 80;
          window.scrollTo({
            top: offsetTop,
            behavior: "smooth"
          });
        }
      }
    });
  });
});
