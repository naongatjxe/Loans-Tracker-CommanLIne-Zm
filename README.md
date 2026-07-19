# Loans Tracker Pro

A premium, modern Flutter application for managing personal loans and aggregates with a clean, intuitive, and responsive interface.

## Premium Features

### 📱 **Onboarding & Permission Flow**
- **Welcome Onboarding Screen**: A visually stunning welcome screen shown on first launch to request required permissions (**Notifications**, **Exact Alarms**, **Storage Write**) and configure the initial export folder.
- **Auto-Detect SDK Level**: Intelligently detects Android 11+ (API 30+) devices to auto-grant storage permissions under Scoped Storage guidelines, while requesting the All Files Access permission (`MANAGE_EXTERNAL_STORAGE`) where appropriate for seamless operation.

### 🎨 **Modern UI/UX**
- **Centered Branded AppBar Layout**: Main screen AppBar displays the wallet brand icon and centered app title "Loans Tracker Pro".
- **Theme Matching**: The welcome screen conforms dynamically to the light/dark mode and accent colors selected in settings.
- **Card Highlight Fixes**: Monthly reports and expandable cards clip touch splashes cleanly using standard Card widgets with zero highlight leaks.

### 🔔 **Customizable Alerts (Reboot Persistent)**
- **Granular Controls**: Exposes notification settings in Settings to enable/disable payment notifications, configure a custom reminder delivery hour/minute via a time picker, and toggle a one-day-before reminder.
- **Daily Overdue Alerts**: Sends daily payment reminders for the first 7 days after a loan becomes overdue.
- **Reboot Persistence**: Automatically reschedules all active reminder notifications after a device reboot by intercepting `BOOT_COMPLETED` broadcasts.

### 📊 **Monthly Reports**
- **Chronological Grouping**: Groups and aggregates loan data by month and year.
- **Details Page**: View totals for principal, interest, active loans, and paid counts.
- **Expandable Overview**: Clean list views for each group.

### 📂 **Data Management, Backup & Restore**
- **Custom Export Folder**: Users can select a custom save folder (using the Storage Access Framework) or fall back to the default `Downloads/Loans Tracker` public folder.
- **Offline JSON Backup & Restore**: Full JSON serialization of database records and user preferences. Supports backing up to local storage (and sharing via system sheets) and restoring data.
- **CSV Exporter**: Generate CSV summaries for loans and monthly report aggregates.

## Supported Platforms
- ✅ Android (Fully optimized for API 21 through API 34+)

## Core Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Local Storage**: SharedPreferences
- **Database**: SQLite (via standard db provider)
- **Notifications**: flutter_local_notifications & timezone
- **System Actions**: share_plus, file_picker, and permission_handler

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/NaongaGondwe/Loans-Tracker-CommanLIne-Zm.git
   cd Loans-Tracker-CommanLIne-Zm
   ```

2. **Clean and fetch dependencies**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## Building Releases
To compile separate, lightweight, and optimized APKs for ARM CPUs (e.g. `armeabi-v7a`, `arm64-v8a`):
```bash
flutter build apk --release --target-platform android-arm,android-arm64 --split-per-abi
```

## Developer
**Naonga Gondwe**  
*CommandLine*
