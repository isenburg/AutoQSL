# AutoQSL - Automated QSL Card Designer & Email Dispatcher for macOS

**AutoQSL** is a native macOS application built with Swift and SwiftUI designed for amateur radio operators. It connects your digital loggers (**WSJT-X**, **RUMlogNG**, and ADIF broadcasts) to an automatic QSL card generation and email dispatch workflow with built-in **QRZ.com** lookup and a full-featured **visual QSL card designer**.

![AutoQSL Card Preview](Sources/AutoQSL/Resources/default_background.jpg)

---

## Key Features

1. 📡 **Live UDP Capture for WSJT-X & RUMlogNG**:
   - Automatically decodes WSJT-X binary broadcast packets (`QSOLogged` on port `2237`).
   - Automatically decodes RUMlogNG and ADIF broadcast packets (on port `2333` or `2237`).

2. 🔍 **QRZ.com XML API Integration**:
   - Automatically looks up DX callsigns to fetch the recipient's email address, full name, QTH address, and grid square.
   - Built-in caching to optimize requests and respect API limits.

3. 🎨 **Interactive Visual QSL Card Designer**:
   - WYSIWYG Drag & Drop card canvas (Standard QSL `3.5" x 5.5" / 140x90mm`, `4" x 6"`, and `16:9`).
   - Customizable background photo with scaling, tint, and contrast controls.
   - **Callsign Typography**: 3D extruded metallic gold, bevel shadows, and custom fonts.
   - **QSO Data Table Grid**: Header and data cells (Callsign, Year, Month, Day, UTC Time, Band, RST, Mode) with custom 73 greeting row.
   - **Badges & Stickers**: ARRL Diamond logo, POTA (Parks on the Air), IOTA (Islands on the Air), SOTA (Summits on the Air), CQ WPX, WAS, plus custom transparent PNG badge imports.
   - Station info footer and multiple card template management.

4. ✉️ **Review & Confirmation Workflow**:
   - When a QSO arrives, AutoQSL renders the card and presents a **Pre-Send Confirmation Dialog** showing the live high-res card preview, recipient email, and editable message.
   - One-click dispatch (`Cmd+Return`) or Skip (`Esc`).
   - Supports 3 sending modes:
     - **Preview & Confirm (Recommended)**: Asks for confirmation before sending each card.
     - **Fully Automatic**: Dispatches immediately upon receiving QSO.
     - **Manual Queue**: Holds in queue for batch review.

5. 🚀 **High-Resolution Card Rendering & Flexible Email Delivery**:
   - Crisp 300 DPI rendering via SwiftUI `ImageRenderer`.
   - **Apple Mail Integration**: Send directly through your macOS Apple Mail app in the background without needing to configure SMTP passwords or server ports.
   - **Default Mail Client Composer**: Opens your default email app composer (Mail, Outlook, Thunderbird, Spark, etc.) pre-filled with the QSL attachment.
   - **Direct SMTP Engine**: Native TLS/SSL SMTP socket engine supporting Gmail, iCloud, Outlook, and custom shack mail servers.

---

## How to Run AutoQSL

### Option 1: Run via Command Line / Swift
```bash
cd "/Users/gi/Library/CloudStorage/Dropbox/300 AFU/Software/AutoQSL"
swift run AutoQSL
```

### Option 2: Run Tests
```bash
swift test
```

### Option 3: Open in Xcode
Open the directory directly in Xcode:
```bash
open -a Xcode "/Users/gi/Library/CloudStorage/Dropbox/300 AFU/Software/AutoQSL"
```

---

## Default Configuration

- **WSJT-X UDP Port**: `2237` (Configurable in Settings)
- **RUMlogNG UDP Port**: `2333` (Configurable in Settings)
- **Default Callsign**: `KG4OJT` (Configurable under Station Profile)
