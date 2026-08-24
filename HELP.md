# AutoQSL – Automated Electronic QSL Card Generator & Dispatcher
**Author:** Georg Isenbürger (DJ6GI)  
**Copyright:** © 2024–2026 Georg Isenbürger · DJ6GI  
**Platform:** macOS 14.0+ (Universal Binary: Apple Silicon & Intel)  
**Repository:** [https://github.com/isenburg/AutoQSL](https://github.com/isenburg/AutoQSL)

---

## 1. Introduction & Overview
AutoQSL is a dedicated native macOS desktop application designed for radio amateurs to automatically generate, render, and dispatch high-resolution electronic QSL cards (eQSL) via email in real time.

### Key Capabilities
- **Real-Time UDP Capture:** Automatically captures QSOs logged in WSJT-X, JTDX, RUMlogNG, N1MM, and other logging software.
- **QRZ.com XML API Integration:** Automatically fetches recipient name, email address, QTH, and Maidenhead grid locator.
- **WYSIWYG Drag & Drop Card Designer:** Interactive canvas with direct mouse drag repositioning, standard macOS color pickers, and native `NSFontPanel` font selection.
- **Customizable Confirmation Table:** Flexible column layouts (`QSO With`, `Date`, `UTC Time`, `Frequency / Band`, `Report`, `Mode`, and custom `Remarks` greeting).
- **Batch Processing:** Select multiple QSOs using `Shift + Arrow Keys` or `Cmd + Click` to easily dispatch or delete them all at once.
- **Multi-Channel Email Delivery:**
  1. **Apple Mail Automation:** Dispatches through native macOS Apple Mail without requiring SMTP server setup or app passwords.
  2. **Default Client:** Opens your default mail client with pre-filled message and attached card.
  3. **Direct SMTP:** Sends directly via SMTP server (Gmail, Outlook, custom mail host) with TLS encryption.

---

## 2. Card Designer Guide
The Card Designer lets you compose high-resolution QSL cards matching standard 3.5" x 5.5" (140x90mm) dimensions.

### Design Elements
1. **My Callsign:** Customizable typeface, size, bold/italic, gold 3D bevel extrusion, neon glow, and drop shadow.
2. **Address Block:** Multi-line text for station address, alignment, and typography.
3. **QSO Table:** Proportional columns with configurable headers, date sequence (`DD MM YYYY` vs `YYYY MM DD`), separators (`.`, `-`, `/`, space), and standard macOS color pickers.
4. **Location / Zone Line:** Placeholders for ITU, CQ, Grid, and County.
5. **Club Badges & Stickers:** ARRL, POTA, SOTA, IOTA, CQ, WAS, and custom badge images.
6. **Drop Shadow Controls:** Dedicated on/off toggles with blur radius and offset sliders for all text elements.

---

## 3. UDP Logging Setup

### WSJT-X / JTDX
1. Open WSJT-X **Settings > Reporting > UDP Server**.
2. Check **Accept UDP requests**.
3. Set **UDP Server:** `127.0.0.1` and **Port:** `2237`.

### RUMlogNG
1. Open RUMlogNG **Preferences > UDP**.
2. Enable **Broadcast ADIF Data** on Port `2333`.

### ⚠️ Important Note on Duplicates
If you have switched on UDP for WSJTX and RumLog in AutoQSL you will get duplicate QSLs depending on RumLog's configuration. It is recommended to use either or.

---

## 4. Email Template Placeholders
- `{DX_CALL}` – Recipient Callsign
- `{DX_NAME}` – Recipient Name
- `{DATE}` – Formatted QSO Date
- `{TIME}` – QSO Time in UTC
- `{BAND}` – Band (e.g. 20m)
- `{MODE}` – Mode (e.g. FT8, CW, SSB)
- `{FREQ}` – Frequency in MHz
- `{RST_SENT}` – Sent RST Report
- `{MY_CALL}` – Your Callsign
- `{MY_GRID}` – Your Grid Square

---

## 5. Automation & Dispatch Modes

AutoQSL offers three automation modes to suit your operating style. These can be configured in the Settings under "Automation & Modes":

- **Preview & Confirm (Recommended):** Whenever a QSO is received, a high-resolution preview of the QSL card is presented. You can verify all details, edit the email message, and click to dispatch.
- **Fully Automatic:** AutoQSL will silently render and email the QSL card in the background immediately upon logging a QSO. This mode is ideal for hands-free FT8 or contesting.
- **Manual Queue:** Incoming QSOs are added to your queue without prompting you. You can review the queue later and use Batch Processing (Shift + Arrow Keys) to send multiple cards at once.

---

## 6. Disclaimer & Privacy Notice

### Disclaimer
AutoQSL is provided **"AS IS"**, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY ARISING FROM THE USE OF THIS SOFTWARE.

### Privacy
AutoQSL operates entirely locally on your Mac. All credentials, settings, templates, and logs are stored locally (`~/Library/Application Support/AutoQSL/`). No telemetry, analytics, or tracking data is collected or transmitted to external servers.

---

## 7. Copyright & License
**Copyright © 2024–2026 Georg Isenbürger · DJ6GI**  
All rights reserved. Released for the global amateur radio community.
