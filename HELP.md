# AutoQSL – User Manual & Operating Guide
**Author:** Georg Isenbürger (DJ6GI)  
**Copyright:** © 2024–2026 Georg Isenbürger · DJ6GI  
**Platform:** macOS 14.0+ (Universal Binary: Apple Silicon & Intel)  
**Repository:** [https://github.com/isenburg/AutoQSL](https://github.com/isenburg/AutoQSL)

---

## 1. Quick Start & Initial Setup (Step-by-Step)

Follow these 4 steps to get AutoQSL up and running in under 2 minutes:

### Step 1: Fill in Your Station Profile
1. Open AutoQSL and switch to the **Settings** tab (gear icon in the top toolbar or press `⌘,`).
2. Under **Station Profile**, enter your:
   - **Callsign** (e.g. `DJ6GI`)
   - **Operator Name** (e.g. `Georg Isenbürger`)
   - **Maidenhead Grid Square** (e.g. `JN58td`)
   - **Postal Address** (printed on cards)
   - **Default QSO Greeting** (e.g. `73, Thanks for the QSO!`)

### Step 2: Configure Callbook Lookups (QRZ.com & HamQTH)
AutoQSL needs recipient email addresses to dispatch eQSL cards. You can use QRZ.com, HamQTH (free), or both:
1. In **Settings > Callbook Lookups**, choose your provider priority:
   - *QRZ.com (Primary) + HamQTH (Fallback)* (Recommended)
   - *HamQTH (Primary) + QRZ.com (Fallback)*
   - *QRZ.com Only* or *HamQTH Only*
2. Under **QRZ.com XML Subscription**, enter your QRZ credentials and click **Test QRZ Connection**.
3. Under **HamQTH.com XML API (Free)**, enter your HamQTH login and click **Test HamQTH Connection**.

### Step 3: Choose Your Email Delivery Method
In **Settings > Email Delivery & SMTP**, select one of three methods:
- **Apple Mail Automation (Recommended for Mac users):** Dispatches directly through macOS Apple Mail in the background. Does not require SMTP server passwords or app passwords.
- **Default Mail Client:** Opens your default mail client composer (Apple Mail, Thunderbird, Outlook, Spark) with the QSL card pre-attached.
- **Direct SMTP Server:** Sends emails directly through an SMTP host (e.g. Gmail, Outlook, custom ISP) with TLS encryption.

### Step 4: Select Your Automation Mode
Under **Settings > Automation & Modes**, choose how you want AutoQSL to react when a contact is logged:
- **Preview & Confirm (Recommended):** Pops up a high-resolution preview of the generated QSL card with the recipient's details. Press `⌘+Return` to dispatch or `Esc` to skip.
- **Fully Automatic:** Silently fetches QRZ info, renders the card, and emails it in the background immediately upon logging. Best for high-rate FT8 or contest operating.
- **Manual Queue:** Queues contacts with status "Ready to Send" without prompting. You can review them later and send them in batches.

---

## 2. Connecting Your Logging Software (UDP Setup)

AutoQSL listens in the background on network UDP ports for logged QSOs.

### WSJT-X / JTDX
1. In WSJT-X or JTDX, open **Preferences / Settings > Reporting > UDP Server**.
2. Check **Accept UDP requests**.
3. Set **UDP Server:** `224.0.0.1` (Multicast) or `127.0.0.1` (Unicast) and **Port:** `2237` (or `2239`).
4. In AutoQSL **Settings > UDP Logging**, verify that the WSJT-X listener is enabled with the matching port.

### RUMlogNG
1. Open RUMlogNG **Preferences > UDP**.
2. Under "Contact info N1MM" broadcasts:
   - If using a second logger utility, set the first broadcast to port `12063`.
   - Set the second broadcast to port `12064` (or `2333`).
3. In AutoQSL **Settings > UDP Logging**, set RUMlogNG port to `12064` and enable the listener.

### ⚠️ How to Avoid Duplicate QSLs
If RUMlogNG is configured to auto-log QSOs from WSJT-X and both WSJT-X and RUMlogNG UDP broadcasts are active in AutoQSL, a QSO might be received twice.
- **Solution:** Either disable WSJT-X UDP listening in AutoQSL (letting RUMlogNG handle the broadcast), or disable RUMlogNG's broadcast for FT8/FT4.

### One-Click RUMlogNG Grab
If you log a QSO manually in RUMlogNG or missed a UDP packet:
- Click the **Grab RUMlog** button in the QSO Queue toolbar. AutoQSL executes an AppleScript query directly to RUMlogNG to import the most recently logged QSO instantly.

---

## 3. Daily Operating & Queue Management

### Monitoring the QSO Queue
The **QSO Queue** tab displays all incoming, pending, and sent contacts with live status badges:
- 🔵 **Looking up QRZ:** Fetching recipient email, name, and location.
- 🟡 **Awaiting Confirmation:** Ready for your review in Preview & Confirm mode.
- 🟢 **Ready to Send:** Card rendered and recipient email verified.
- 🚀 **Sent:** Successfully dispatched via email.
- 🔴 **Failed / Email missing:** Recipient email was not found on QRZ; click "Edit QSO" to enter an email address manually.

### Reviewing & Sending Cards (Preview & Confirm)
1. When a QSO arrives, the **Confirmation Sheet** opens with a 300 DPI preview of the card.
2. Review the recipient's email address and customize the email message if desired.
3. Keyboard Shortcuts:
   - `⌘ + Return`: Send QSL card immediately.
   - `Esc`: Skip/dismiss without sending.

### Batch Processing & Multi-Selection
1. In the QSO Queue table, select multiple QSOs using:
   - `Shift + Up/Down Arrow`: Range selection.
   - `⌘ + Click`: Toggle individual selections.
   - `⌘A`: Select all QSOs in the queue.
2. Use the bottom toolbar buttons:
   - **Send Selected:** Renders and dispatches all selected QSOs in sequence.
   - **Delete Selected:** Removes selected QSOs permanently from the queue and database.

### Manual QSO Logging
To log an offline, ragchew, or non-digital QSO:
1. Click **Log QSO Manually** in the toolbar.
2. Enter the **Callsign** (email can be looked up automatically or entered manually).
3. Select the **Band** or enter the **Frequency in MHz** (typing a frequency like `14.074` automatically detects and sets the `20m` band; choosing a band auto-populates the default frequency).
4. Select the **Mode** from the dropdown or pick **Other...** to type any custom mode (e.g. `VARAC`, `JT65`, `DMR`, `WSPR`).
5. Set the RST reports and optional greeting comment.
6. Click **Add & Process QSL**.

---

## 4. Callbook Lookups (QRZ.com & HamQTH.com)

AutoQSL integrates automatic online callbook querying to retrieve recipient contact details in real time.

### Why Are Callbooks Important?
To dispatch electronic QSL cards by email, AutoQSL needs the recipient's email address. Callbooks provide:
- **Email Address:** Direct destination for card delivery.
- **Operator Name:** Personalized greetings in email bodies and QSL cards.
- **Maidenhead Grid Square & DXCC:** Automatic recipient location data.
- **Postal Address:** Recipient street and city information.

---

### Supported Callbook Providers

#### 1. QRZ.com XML Subscription
- **Description:** Comprehensive global database maintained by QRZ.com.
- **Requirements:** Requires an active QRZ XML Logbook Data subscription (or XML-enabled subscriber account).
- **Setup:**
  1. Open **Settings > Callbook Lookups**.
  2. Enable **QRZ.com Lookups**.
  3. Enter your QRZ username (callsign) and password.
  4. Click **Test QRZ Connection** to verify.

#### 2. HamQTH.com XML API (100% Free)
- **Description:** Community-driven amateur radio callbook provided by Petr, OK2CQR.
- **Requirements:** Free account on [hamqth.com](https://www.hamqth.com) (no paid subscription required).
- **Setup:**
  1. Register for a free account at [https://www.hamqth.com](https://www.hamqth.com) if you do not have one.
  2. In AutoQSL **Settings > Callbook Lookups**, enable **HamQTH.com Lookups**.
  3. Enter your HamQTH login and password.
  4. Click **Test HamQTH Connection**.

---

### Lookup Priority & Fallback Modes

In **Settings > Callbook Lookups**, choose your preferred lookup strategy:
- **QRZ.com (Primary) + HamQTH (Fallback) [Recommended]:** Queries QRZ.com first. If QRZ does not have an email address or the profile is not found, AutoQSL seamlessly queries HamQTH.com.
- **HamQTH (Primary) + QRZ.com (Fallback):** Queries free HamQTH.com first, falling back to QRZ.com if needed.
- **QRZ.com Only:** Only queries QRZ.com.
- **HamQTH Only:** Only queries HamQTH.com (ideal for operators without a paid QRZ XML subscription).

---

### In-Memory Caching
To minimize API bandwidth and guarantee instant UI responsiveness, AutoQSL caches callbook profiles in memory during each session.

---

## 5. How to Use the QSL Card Designer

Open the **Card Designer** tab to create, customize, and manage your QSL card templates.

### Direct On-Canvas Editing vs. Sidebar Inspector

| Designer Element | How to Edit | Features & Options |
| :--- | :--- | :--- |
| **Callsign Block** | ✅ **Directly on Canvas** (Click and type) | Font family, size, bold/italic, gold 3D bevel extrusion, neon glow, drop shadows |
| **Address Block** | ✅ **Directly on Canvas** (Click and type) | Multi-line text for station address, alignment (left/center/right), typography |
| **Custom Text** | ✅ **Directly on Canvas** (Click and type) | Custom remarks, slogans, or template placeholders (e.g. `{MY_CALL}`, `{DX_CALL}`) |
| **QSO Table** | ⚙️ **Right Sidebar Inspector** | Toggle columns (`Date`, `UTC`, `Freq/Band`, `RST`, `Mode`, `Remarks`), headers, date format & separators, table background/border colors & opacity |
| **Location Line** | ⚙️ **Right Sidebar Inspector** | Automatic placeholders for `GRID`, `ITU`, `CQ`, and `COUNTY` zones |
| **Stickers & Badges**| 🛡️ **Toolbar Badge Picker** | Badges & Stickers collection: Built-in ARRL Diamond, POTA, SOTA, IOTA, CQ, WAS badges + custom PNG/SVG logo imports, deletion, and 1-click placement |
| **Background & Size**| ⚙️ **Right Sidebar Inspector** | Card aspect ratio (Standard QSL `3.5" x 5.5" / 140x90mm`, `4" x 6"`, `16:9`), background image upload, and tint/darken overlays |

### Step-by-Step Designer Workflow
1. **Choose or Create a Template:** Select a template from the top dropdown or click `+` to start a new design.
2. **Set Background:** Click "Background Picture" in the layer list and choose a photo from your Mac (landscape orientation recommended). Adjust the darken slider for text readability.
3. **Edit Your Callsign:** Double-click your callsign on the canvas (or edit in the sidebar inspector) to type your call. Use the right sidebar to apply 3D gold extrusion or neon glow.
4. **Position Elements:** Single-click and drag any element smoothly across the canvas to reposition it (with true WYSIWYG scale compensation).
5. **Add Badges & Stickers:** Click the **Badge** button in the toolbar to open the Badges Collection. Pick from built-in award badges or click **Add Sticker...** to import your club logo.
6. **Format the QSO Table:** Click the table in the layer list. In the inspector, choose which columns to display and select your preferred date format (`DD.MM.YYYY` vs `YYYY.MM.DD`).
7. **Undo Any Mistake:** Press `⌘Z` (or click the Undo arrow in the toolbar) to revert any design change.
8. **Preview with Real Data:** Use the "Preview" dropdown in the toolbar to test how your card looks with real QSOs from your log.

### Custom Card Design for a Specific QSO
You can customize the card design for an individual QSO without affecting your default template:
- Select the contact in the QSO Queue and click **Edit QSO > Customize Card Layout**.

---

## 6. Storage, Sync & Backup

AutoQSL uses a high-performance **SQLite database** (`autoqsl.sqlite`) to store all contacts and supports seamless multi-Mac synchronization.

### Switching Between Local and iCloud Storage
1. Open **Settings > Storage & Database**.
2. Choose:
   - **Local Storage:** `~/Library/Application Support/AutoQSL/`
   - **iCloud Drive:** `iCloud Drive/AutoQSL/` (automatically synchronizes your settings, card templates, and log queue across all your Macs logged into the same Apple ID).
3. Use **Migrate Data to Destination** to effortlessly transfer all templates, settings, and QSO history between Local and iCloud storage.
4. Click **Reveal in Finder** to access your database and rendered cards folder directly.

---

## 7. Dynamic Placeholders & Template Guide

AutoQSL supports dynamic `{TAG}` placeholders that automatically populate real QSO information and station profile values.

### Where Can You Use Placeholders?
1. **Email Subject & Message Body** (*Settings > Email Template*): Customize your outgoing email messages so every recipient receives a personalized email.
2. **QSL Card Canvas (Custom Text Elements)** (*Card Designer > Add Element > Custom Text*): Add dynamic text blocks directly onto your QSL card (e.g., `"73 to {DX_CALL} from {MY_CALL}"`).
3. **Card Location Footer** (*Card Designer > Location Footer*): Display your station zones and grids (e.g., `"ITU {MY_ITU} • CQ {MY_CQ} • Grid {MY_GRID}"`).

---

### Complete List of Available Placeholders

#### 📡 DX Contact Information (Fetched from Log & QRZ.com)
| Placeholder | Description | Example Output |
| :--- | :--- | :--- |
| `{DX_CALL}` or `{CALL}` | Recipient's Callsign | `DJ6GI` |
| `{DX_NAME}` or `{NAME}` | Recipient's Name (from QRZ or fallback to Callsign) | `Gerd Ihde` |
| `{DX_GRID}` | Recipient's Maidenhead Grid Locator | `JN58td` |
| `{DX_EMAIL}` | Recipient's Email Address | `dj6gi@example.com` |
| `{DX_COUNTRY}` | Recipient's Country / DXCC Entity | `Germany` |

#### 📻 QSO Parameters
| Placeholder | Description | Example Output |
| :--- | :--- | :--- |
| `{BAND}` | Operating Band | `20m` |
| `{MODE}` | Operating Mode | `FT8` (or `CW`, `SSB`, `VARAC`) |
| `{FREQ}` | Exact Frequency with unit | `14.074 MHz` |
| `{RST_SENT}` | Signal report sent by you | `-12` (or `59`) |
| `{RST_RCVD}` | Signal report received from DX | `-08` (or `59`) |
| `{DATE}` | Full QSO Date (formatted per settings) | `25.08.2026` or `2026.08.25` |
| `{TIME}` | QSO Time in UTC | `14:30` |
| `{YEAR}` | 4-Digit UTC Year | `2026` |
| `{MONTH}` | 2-Digit UTC Month | `08` |
| `{DAY}` | 2-Digit UTC Day | `25` |
| `{COMMENT}` | QSO Comment / Personal Remarks | `73, Thanks for the QSO!` |

#### 🏠 My Station Information (*From Settings > Station Profile*)
| Placeholder | Description | Example Output |
| :--- | :--- | :--- |
| `{MY_CALL}` | Your Station Callsign | `KG4OJT` |
| `{MY_NAME}` | Your Operator Name | `Pete Norloff` |
| `{MY_GRID}` | Your Maidenhead Grid Square | `FM18iv` |
| `{MY_STREET}` | Your Street Address | `123 Radio Way` |
| `{MY_CITY}` | Your City | `Munich` |
| `{MY_STATE}` | Your State / Province | `BY` |
| `{MY_COUNTRY}` | Your Country | `Germany` |
| `{MY_CQ}` | Your CQ Zone | `14` |
| `{MY_ITU}` | Your ITU Zone | `28` |
| `{MY_COUNTY}` | Your County / Region | `Oberbayern` |

---

### Practical Examples

#### Example 1: Personalized Email Subject Line
```
eQSL from {MY_CALL} to {DX_CALL} for {BAND} {MODE} QSO
```
*Renders as:* `eQSL from KG4OJT to DJ6GI for 20m FT8 QSO`

#### Example 2: Outgoing Email Message Body
```
Hello {DX_NAME},

Thank you very much for the nice {MODE} QSO on {BAND} ({FREQ}) on {DATE} at {TIME} UTC!
Your signal report was {RST_SENT} into grid {MY_GRID}.

Please find my electronic QSL card attached to this email.

{COMMENT}

Best 73 & Good DX,
{MY_NAME} ({MY_CALL})
Grid: {MY_GRID} • CQ Zone: {MY_CQ}
```

#### Example 3: Card Designer Custom Text Block
- Add a **Custom Text** element to the top of your card:
  `"Confirming 2-way {MODE} QSO with {DX_CALL}"`
- Add a **Location Line** at the bottom of your card:
  `"QTH: {MY_CITY}, {MY_COUNTRY} • Locator: {MY_GRID} • ITU {MY_ITU}"`

---

## 8. Keyboard & Mouse Shortcuts Reference

### Global Navigation & Actions
| Shortcut | Action | Scope |
| :--- | :--- | :--- |
| `⌘,` | Open Settings | Global |
| `⌘?` | Open Help & Documentation | Global |
| `⌘1` | Switch to QSO Queue | Global |
| `⌘2` | Switch to Card Designer | Global |
| `⇧ + ⌘G` | Grab last QSO from RUMlogNG | Global |
| `⇧ + ⌘K` | Simulate test QSO | Global |

### QSO Queue & Management
| Shortcut / Gesture | Action | Scope |
| :--- | :--- | :--- |
| `Click` | Select and highlight entry; view details | QSO Queue |
| `⌘A` | Select all QSOs in the current list | QSO Queue |
| `⌘ + Click` | Multi-select / toggle individual QSOs | QSO Queue |
| `⇧ + Click` / `⇧ + ↑ / ↓` | Select a range of QSOs | QSO Queue |
| `Delete` / `⌫` | Delete selected QSO(s) | QSO Queue |
| `Right-Click` | Open context menu (Send, Lookup, Delete) | QSO Queue |
| `Click Callbook Icon` | Open QRZ.com / HamQTH in browser | QSO Detail View |

### Confirmation Sheet & Dialogs
| Shortcut | Action | Scope |
| :--- | :--- | :--- |
| `⌘ + Return` | Confirm & Send QSL card immediately | Confirmation Preview Sheet |
| `Esc` | Skip / Dismiss without sending | All Sheets & Modals |
| `Return` | Save / Confirm default action | Add / Edit QSO Dialogs |

### QSL Card Designer
| Shortcut / Gesture | Action | Scope |
| :--- | :--- | :--- |
| `⌘Z` | Undo last design change | Card Designer |
| `⇧ + ⌘Z` | Redo last undone design change | Card Designer |
| `Click` | Select element and open inspector | Card Designer Canvas |
| `Double-Click` | Direct inline text editing (Callsign, Address, Text) | Card Designer Canvas |
| `Drag` | Move element position | Card Designer Canvas |
| `Drag Handles` | Resize element | Card Designer Canvas |

---

## 9. Disclaimer, Privacy & License

### Disclaimer
AutoQSL is provided **"AS IS"**, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY ARISING FROM THE USE OF THIS SOFTWARE.

### Privacy
AutoQSL operates entirely locally on your Mac. All credentials, settings, templates, and logs are stored locally or in your private encrypted iCloud Drive. No telemetry, analytics, or tracking data is collected or transmitted to external servers.

### Copyright
**Copyright © 2024–2026 Georg Isenbürger · DJ6GI**  
Released for the global amateur radio community.

---

## 10. Changelog & Version History

### Version 1.1.0 (2026-08)
- 🔍 **HamQTH.com XML Callbook Integration**: Native support for free HamQTH callbook lookups with fallback and dual-lookup priority modes.
- 🖱️ **Callbook Lookup via Context Menu**: Right-clicking any queue entry (or clicking the Callbook button in the detail view) opens the callsign in your configured callbook (QRZ.com or HamQTH.com) in the browser.
- ✅ **Native Queue Selection**: Single-click selects entries with standard macOS highlight; `⌘A` selects all; `⌘+click` / `Shift+click` for multi-select.
- 📡 **Improved RUMlogNG UDP Parsing**: Full N1MM XML contact format support (CDATA, 10 Hz frequency units, UTF-8/Latin-1 encoding).
- 🔒 **Port Isolation**: AutoQSL only binds explicitly configured ports and never auto-binds fallback ports that could conflict with other apps.
- ⌨️ **Native Settings Shortcut**: Standard macOS `⌘,` shortcut to open Settings from any window or menu.
- ✏️ **Direct On-Canvas Editing**: Edit Callsign, Address Block, and Custom Text directly on the interactive card canvas in addition to the inspector sidebar.
- 📻 **Band & Frequency Selection**: Dynamic two-way synchronization between Band and Frequency fields in both "Log QSO Manually" and "Edit QSO" dialogs.
- ⚡ **Auto Band Detection**: Typing frequency in MHz automatically selects the matching amateur band; selecting a band auto-populates the default frequency.
- 🎛️ **Custom Modes & Bands**: Added custom mode text input when selecting "Other..." or using non-standard modes (`VARAC`, `JT65`, `DMR`, `C4FM`, `D-STAR`, `WSPR`, etc.), and custom band support.
- 💾 **SQLite Queue Synchronization**: Permanent deletion synchronization and prevention of duplicate legacy re-imports across restarts.
- 🧪 **Radio Engine & Tests**: Centralized `RadioUtils` helper and 10/10 passing unit tests for frequency calculations, ADIF/RUMlog/WSJT-X parsing, and custom QSO logging.

### Version 1.0.0 (2026-08)
- Initial public release of AutoQSL for macOS.
- Real-time UDP capture for WSJT-X, JTDX, and RUMlogNG.
- WYSIWYG QSL card designer with layer management, drag-and-drop, badges, and undo support.
- QRZ.com XML API automatic lookup for email, name, and QTH.
- Multi-channel email delivery (Apple Mail, Default Mail Client, direct SMTP).
- SQLite storage backend with optional iCloud Drive sync.
- Preview & Confirm, Fully Automatic, and Manual Queue automation modes.
