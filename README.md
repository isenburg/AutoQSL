# AutoQSL - Automated QSL Card Designer & Email Dispatcher for macOS

**AutoQSL** is a native macOS application built with Swift and SwiftUI designed for amateur radio operators. It connects your digital loggers (**WSJT-X**, **JTDX**, **RUMlogNG**, and ADIF broadcasts) to an automated QSL card generation and email dispatch workflow with built-in **QRZ.com** lookup, a high-performance **SQLite database engine**, optional **iCloud Drive synchronization**, and a full-featured **visual QSL card designer**.

![AutoQSL Card Preview](Sources/AutoQSL/Resources/default_background.jpg)

---

## Key Features

1. 📡 **Live UDP Capture & RUMlogNG AppleScript Grab**:
   - **WSJT-X / JTDX**: Automatically decodes binary broadcast packets (`QSOLogged` on port `2237` or `2239` / Multicast `224.0.0.1`).
   - **RUMlogNG**: Real-time ADIF UDP broadcast reception (port `12064` / `12060` / `2333`) with automatic `SUBMODE` (FT4/FT8) recognition.
   - **One-Click RUMlog Grab**: Instant AppleScript button (`Grab RUMlog`) to pull the latest QSO directly from RUMlogNG.
   - ⚠️ *Tip*: It is recommended to enable either WSJT-X or RUMlog UDP in AutoQSL depending on whether RUMlog forwards WSJT-X logs, avoiding duplicate entries.

2. 🔍 **QRZ.com XML API Integration**:
   - Automatically looks up DX callsigns to fetch the recipient's email address, full name, QTH address, and Maidenhead grid square.
   - Local in-memory caching to optimize requests and respect API limits.

3. 🎨 **Interactive Visual QSL Card Designer**:
   - WYSIWYG card canvas with customizable aspect ratios (Standard QSL `3.5" x 5.5" / 140x90mm`, `4" x 6"`, and `16:9`).
   - **Full Layer Management**: Callsign typography, custom text blocks, QSO data table grid, location footers, and badges/stickers.
   - **Opacity & Colors**: macOS native color picker with full alpha opacity channel support on all text, background tints, and element borders.
   - **Undo Support**: Full `⌘Z` keyboard shortcut and toolbar button for reversible design changes.
   - **Badges & Stickers**: ARRL Diamond, POTA, IOTA, SOTA, CQ WPX, WAS, plus custom transparent PNG badge imports.

4. ✉️ **Review & Automation Modes**:
   - **Preview & Confirm (Recommended)**: Presents a high-resolution preview dialog with recipient email and editable message before sending (`⌘+Return` to send, `Esc` to skip).
   - **Fully Automatic**: Dispatches immediately upon receiving a QSO without requiring user interaction. Perfect for hands-free contesting or FT8/FT4 operating.
   - **Manual Queue**: Holds incoming QSOs in the queue with a "Ready to Send" status for later batch review.
   - **Multi-Selection & Batch Actions**: Select multiple QSOs (`Shift + Arrow Keys` or `Cmd + Click`) to batch send or delete.
   - **Resizable UI**: Persistent divider positions (`NSSplitView`) and customizable window sizes across restarts.

5. 💾 **SQLite Database & iCloud Drive Sync**:
   - **macOS-Native SQLite (`autoqsl.sqlite`)**: High-speed, indexed database for instant searches and low memory usage even with 100,000+ QSOs.
   - **Dual Storage Options**: Switch between Local Storage (`~/Library/Application Support/AutoQSL`) and **iCloud Drive** (`iCloud Drive/AutoQSL`) for seamless multi-Mac synchronization.
   - **1-Click Data Migration**: Effortlessly copy or restore settings, templates, and QSO logs between local disk and iCloud.

6. 🚀 **High-Resolution Card Rendering & Flexible Email Delivery**:
   - Crisp 300 DPI rendering via SwiftUI `ImageRenderer`.
   - **Apple Mail Integration**: Sends directly through your macOS Apple Mail app in the background without needing SMTP server passwords.
   - **Default Mail Client Composer**: Opens your default email app composer (Mail, Outlook, Thunderbird, Spark, etc.) pre-filled with the QSL attachment.
   - **Direct SMTP Engine**: Native TLS/SSL SMTP socket engine supporting Gmail, iCloud, Outlook, and custom shack mail servers.

---

## How to Run AutoQSL

### Quick Start (Build & Launch)
```bash
./run.sh
```

### Run via Swift Package Manager
```bash
swift run AutoQSL
```

### Open in Xcode
```bash
open -a Xcode .
```

---

## Keyboard Shortcuts

| Shortcut | Description |
| :--- | :--- |
| `⌘Z` | Undo last change in Card Designer |
| `⌘↩` (Cmd+Return) | Send QSL card in Confirmation Sheet |
| `Esc` | Skip/Dismiss Confirmation Sheet |
| `⌘A` | Select all QSOs in Queue |
| `⇧ + ↑/↓` | Multi-select QSO items in Queue |

---

## Default Configuration

- **Callsign**: `DJ6GI` (Configurable under Station Profile)
- **WSJT-X UDP**: Port `2239` / Address `224.0.0.1` (Multicast)
- **RUMlogNG UDP**: Port `12064` / Address `127.0.0.1`
- **Storage**: SQLite (`autoqsl.sqlite`) + Dual Local / iCloud Drive
- **Delivery**: Apple Mail (Recommended for macOS)

---

## Changelog

### Version 1.1.0 (2026-08)
- 🔍 **HamQTH.com Callbook Lookup**: Added full integration for HamQTH XML callbook lookups with customizable provider priorities (QRZ Primary + HamQTH Fallback, HamQTH Primary, QRZ Only, HamQTH Only).
- ⌨️ **Native Settings Shortcut**: Bound Settings to standard macOS `⌘,` (Command-Comma) shortcut across all app menus and active views.
- ✏️ **Direct On-Canvas Editing**: Edit Callsign, Address Block, and Custom Text directly on the interactive card canvas in addition to the inspector sidebar.
- 📻 **Band & Frequency Selection**: Dynamic two-way synchronization between Band and Frequency fields in both "Log QSO Manually" and "Edit QSO" dialogs.
- ⚡ **Auto Band Detection**: Typing frequency in MHz automatically selects the matching amateur band; selecting a band auto-populates the default frequency.
- 🎛️ **Custom Modes & Bands**: Added custom mode text input when selecting "Other..." or using non-standard modes (`VARAC`, `JT65`, `DMR`, `C4FM`, `D-STAR`, `WSPR`, etc.), and custom band support.
- 💾 **SQLite Queue Synchronization**: Permanent deletion synchronization and prevention of duplicate legacy re-imports across restarts.
- 🧪 **Radio Engine & Tests**: Centralized `RadioUtils` helper and unit tests for frequency calculations and custom QSO logging.

### Version 1.0.0 (2026-08)
- 🚀 Initial public release of AutoQSL for macOS.
- 📡 Real-time UDP capture from WSJT-X / JTDX / RUMlogNG and AppleScript instant QSO grab.
- 🔍 Automatic QRZ.com XML API lookup for recipient name, email, and QTH.
- 🎨 Interactive WYSIWYG QSL card designer with drag-and-drop layer positioning, undo (`⌘Z`), and badge overlays.
- ✉️ Multi-channel email dispatching via Apple Mail automation, default mail client, or direct SMTP.
- 💾 High-speed SQLite database engine (`autoqsl.sqlite`) and dual local / iCloud Drive synchronization.

---

## Author & Copyright

**AutoQSL**
Copyright © 2024–2026 Georg Isenbürger · DJ6GI
Crafted for the global amateur radio community.
