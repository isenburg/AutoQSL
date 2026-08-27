// AutoQSL Marketing Website Interactivity & Bilingual Logic

const translations = {
  de: {
    heroTag: "Version 2.0 für macOS",
    heroTitle: "Elektronische QSL-Karten in Sekunden. Vollautomatisch.",
    heroSubtitle: "Die moderne macOS-App für Funkamateure. Lauscht per UDP auf WSJT-X, JTDX & Logger, gestaltet 300-DPI Druckkarten, fragt QRZ.com ab und versendet fertige QSL-Karten per E-Mail oder druckt direkt auf Postkarten.",
    ctaAppStore: "Im Mac App Store laden",
    ctaFeatures: "Funktionen entdecken",
    navFeatures: "Funktionen",
    navDesigner: "QSL-Designer",
    navWorkflow: "Ablauf",
    navGallery: "Screenshots",
    navPricing: "Preise",
    navFaq: "FAQ",
    navLegal: "Rechtliches",
    bentoHeaderTag: "Leistungsmerkmale",
    bentoHeaderTitle: "Alles, was der moderne Funkamateur braucht.",
    bentoHeaderDesc: "Keine manuellen Exporte, keine mühsame Bildbearbeitung. AutoQSL integriert sich nahtlos in dein macOS-Shack.",
    bento1Title: "Zero-Click UDP Listener",
    bento1Desc: "Lauscht im Hintergrund auf Port 2237 / 2333. Sobald du ein QSO in WSJT-X, JTDX, RUMlogNG oder MacLoggerDX loggst, übernimmt AutoQSL alle Daten sofort.",
    bento2Title: "Visueller 300-DPI QSL Designer",
    bento2Desc: "Echte Gestaltungsfreiheit: Drag & Drop, 6 interaktive Anfasser, macOS System-Schriften, Gold- & 3D-Effekte, transparente Hintergründe und offizielle Verbands-Badges (DARC, ARRL, POTA, WWFF, IOTA, SOTA).",
    bento3Title: "Automatische Callbook-Abfragen",
    bento3Desc: "Echtzeit-Abfrage von QRZ.com (XML API) und HamQTH.com für E-Mail-Adressen, Namen, QTH und Zonen-Daten.",
    bento4Title: "Multi-Kanal E-Mail-Versand",
    bento4Desc: "Versende QSL-Karten direkt per integriertem SMTP oder vollautomatisch über Apple Mail mit personalisiertem Text.",
    bento5Title: "Direkter Postkarten-Druck (⌘P)",
    bento5Desc: "Drucke hochauflösende QSL-Karten direkt auf deinen Fotodrucker oder Postkartenkarton.",
    bento6Title: "100% Private iCloud Synchronisation",
    bento6Desc: "Keine Drittanbieter-Server. Alle Einstellungen, Vorlagen und Logs verbleiben verschlüsselt auf deinem Mac und im persönlichen iCloud Drive.",
    workflowTag: "Workflow",
    workflowTitle: "In 4 Schritten zur perfekten QSL-Karte",
    step1Title: "1. QSO loggen",
    step1Desc: "QSO wie gewohnt in WSJT-X, JTDX oder deinem Logger speichern.",
    step2Title: "2. Auto-Erkennung",
    step2Desc: "AutoQSL empfängt die Daten per UDP und ermittelt Mail & Name via QRZ.",
    step3Title: "3. Karte generieren",
    step3Desc: "Deine individuelle Kartenvorlage wird mit echten QSO-Daten gerendert.",
    step4Title: "4. Senden oder Drucken",
    step4Desc: "Automatischer Versand per E-Mail oder 1-Klick Papier-Druck (⌘P).",
    pricingTag: "Faires Preismodell",
    pricingTitle: "Voller Funktionsumfang. Ein transparenter Preis.",
    priceSub: "4,99 € / Jahr (inkl. MwSt.)",
    priceNote: "Abrechnung jährlich über deine Apple-ID im Mac App Store. Jederzeit mit einem Klick in den macOS-Account-Einstellungen kündbar.",
    priceF1: "Unbegrenzte QSL-Karten & Vorlagen",
    priceF2: "UDP Listener für WSJT-X, JTDX, RUMlogNG, MacLoggerDX",
    priceF3: "QRZ.com & HamQTH.com XML-Schnittstellen",
    priceF4: "SMTP-Versand & Apple Mail Automation",
    priceF5: "300 DPI QSL-Designer & Direktdruck (⌘P)",
    priceF6: "iCloud Sync zwischen mehreren Macs",
    priceF7: "Alle zukünftigen Updates & neue Badges inklusive",
    faqTag: "Häufige Fragen",
    faqTitle: "Fragen & Antworten",
    footerCopyright: "© 2024–2026 GLOMATEC GmbH, 22765 Hamburg. Entwickelt von Georg Isenbürger (DJ6GI)."
  },
  en: {
    heroTag: "Version 2.0 for macOS",
    heroTitle: "Electronic QSL Cards in Seconds. Fully Automated.",
    heroSubtitle: "The premier macOS utility for radio amateurs. Captures UDP broadcasts from WSJT-X, JTDX & Loggers, designs 300-DPI print cards, looks up QRZ.com, and sends high-res cards via email or direct printing.",
    ctaAppStore: "Download on Mac App Store",
    ctaFeatures: "Explore Features",
    navFeatures: "Features",
    navDesigner: "QSL Designer",
    navWorkflow: "Workflow",
    navGallery: "Screenshots",
    navPricing: "Pricing",
    navFaq: "FAQ",
    navLegal: "Legal Notice",
    bentoHeaderTag: "Core Capabilities",
    bentoHeaderTitle: "Everything the Modern Ham Needs.",
    bentoHeaderDesc: "No manual exports, no cumbersome image editors. AutoQSL integrates seamlessly into your macOS ham shack.",
    bento1Title: "Zero-Click UDP Listener",
    bento1Desc: "Listens in background on Port 2237 / 2333. When you log in WSJT-X, JTDX, RUMlogNG, or MacLoggerDX, AutoQSL captures the QSO instantly.",
    bento2Title: "Visual 300-DPI QSL Designer",
    bento2Desc: "True creative freedom: Drag & drop, 6 resize handles, macOS system font panel, 3D metallic gold effects, opacity sliders, and official society badges (DARC, ARRL, POTA, WWFF, IOTA, SOTA).",
    bento3Title: "Real-Time Callbook Lookups",
    bento3Desc: "Automatic XML queries to QRZ.com and HamQTH.com for recipient email addresses, operator names, QTH, and grid locators.",
    bento4Title: "Multi-Channel Email Dispatch",
    bento4Desc: "Send personalized QSL emails via direct built-in SMTP or background Apple Mail automation.",
    bento5Title: "Direct Postcard Printing (⌘P)",
    bento5Desc: "Print high-resolution QSL cards directly onto photo paper or postcard blanks using native macOS print dialogs.",
    bento6Title: "100% Private iCloud Sync",
    bento6Desc: "Zero third-party telemetry. All settings, credentials, and custom templates remain securely encrypted on your Mac and private iCloud Drive.",
    workflowTag: "Workflow",
    workflowTitle: "Perfect QSL Cards in 4 Steps",
    step1Title: "1. Log QSO",
    step1Desc: "Log your contact as usual in WSJT-X, JTDX, or your logger.",
    step2Title: "2. Auto-Capture",
    step2Desc: "AutoQSL catches UDP broadcast and fetches email/name from QRZ.",
    step3Title: "3. Render Card",
    step3Desc: "Your custom template is instantly rendered with live QSO data.",
    step4Title: "4. Send or Print",
    step4Desc: "Dispatched automatically via email or printed with 1 click (⌘P).",
    pricingTag: "Fair & Transparent",
    pricingTitle: "Full Power. One Clear Price.",
    priceSub: "€ 4.99 / year (incl. VAT)",
    priceNote: "Billed annually via your Apple ID in the Mac App Store. Easily cancel anytime in macOS Account Settings with 1 click.",
    priceF1: "Unlimited QSL cards & templates",
    priceF2: "UDP Listener for WSJT-X, JTDX, RUMlogNG, MacLoggerDX",
    priceF3: "QRZ.com & HamQTH.com XML integrations",
    priceF4: "SMTP dispatch & Apple Mail automation",
    priceF5: "300 DPI visual designer & direct printing (⌘P)",
    priceF6: "iCloud Sync across all your Macs",
    priceF7: "All future updates & official badges included",
    faqTag: "Frequently Asked Questions",
    faqTitle: "Questions & Answers",
    footerCopyright: "© 2024–2026 GLOMATEC GmbH, 22765 Hamburg. Developed by Georg Isenbürger (DJ6GI)."
  }
};

let currentLang = 'de';

function setLanguage(lang) {
  currentLang = lang;
  document.documentElement.lang = lang;
  
  const dict = translations[lang];
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (dict[key]) {
      el.textContent = dict[key];
    }
  });

  const langBtnText = document.getElementById('langBtnText');
  if (langBtnText) {
    langBtnText.textContent = lang === 'de' ? '🇩🇪 Deutsch' : '🇬🇧 English';
  }
}

function toggleLanguage() {
  setLanguage(currentLang === 'de' ? 'en' : 'de');
}

// Modal handling
function openModal(modalId) {
  const m = document.getElementById(modalId);
  if (m) {
    m.classList.add('active');
    document.body.style.overflow = 'hidden';
  }
}

function closeModal(modalId) {
  const m = document.getElementById(modalId);
  if (m) {
    m.classList.remove('active');
    document.body.style.overflow = '';
  }
}

// Lightbox for Gallery
function openLightbox(imgSrc, caption) {
  const modal = document.getElementById('lightboxModal');
  const img = document.getElementById('lightboxImg');
  const cap = document.getElementById('lightboxCaption');
  if (modal && img) {
    img.src = imgSrc;
    if (cap) cap.textContent = caption || '';
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
  }
}

// Initialize interactive components
document.addEventListener('DOMContentLoaded', () => {
  // Setup FAQ Accordion
  document.querySelectorAll('.faq-question').forEach(q => {
    q.addEventListener('click', () => {
      const item = q.parentElement;
      const isActive = item.classList.contains('active');
      document.querySelectorAll('.faq-item').forEach(i => i.classList.remove('active'));
      if (!isActive) {
        item.classList.add('active');
      }
    });
  });

  // Modal backdrop click close
  document.querySelectorAll('.modal').forEach(m => {
    m.addEventListener('click', (e) => {
      if (e.target === m) {
        m.classList.remove('active');
        document.body.style.overflow = '';
      }
    });
  });

  // Default Language
  setLanguage('de');
});
