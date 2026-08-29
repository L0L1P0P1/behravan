# Behravan (بهر‌روان) — Pediatric Bladder & Bowel Tracker

Behravan is an offline-first Flutter application designed for parents and pediatric clinicians to monitor, manage, and report pediatric lower urinary tract symptoms, daytime timed voiding, nocturnal enuresis, and bowel dysfunction.

---

## Core Features

- **Customizable Timed Voiding:**
  - Configurable daytime active window (e.g., `08:00` to `20:00`).
  - Adjustable intervals ($60$, $90$, $120$, $150$, $180$ minutes).
  - Auto-resetting timers upon logging a voiding event.
  - Interactive lock-screen notification actions (`Peed Successfully`, `Had Accident`).
- **Daytime Voiding Logs:** Track event types (prompted, spontaneous, accidents), urgency levels ($1$ to $3$), and volume estimations.
- **Nocturnal Enuresis Calendar:** Interactive monthly calendar tracking dry/wet nights, wake-to-void events, evening fluid restriction, and dry streaks.
- **Bowel Movement Diary:** 7-stage Bristol Stool Scale visual selector, straining intensity ($1$ to $3$), hematochezia (blood in stool), and encopresis / soiling flags.
- **Clinical Data Export:**
  - Multi-page structured PDF reports formatted for pediatric urologists/nephrologists.
  - Multi-table CSV exports across all three clinical logging domains.

---

## Tech Stack & Architecture

- **Framework:** Flutter (Material 3, RTL Persian & English localization support)
- **State Management:** Riverpod 2.x (`StreamProvider`, `ConsumerStatefulWidget`)
- **Local Database:** Drift (SQLite with WAL mode enabled via `sqlite3_flutter_libs`)
- **Notifications & Background Tasks:** `flutter_local_notifications` with timezone-aware exact alarms and background isolate response handlers
- **Document Generation:** `pdf`, `printing`, `path_provider`

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.13.0` or higher
- Android SDK (minSdkVersion 21+, targetSdkVersion 34+)

### Installation & Code Generation

1. Clone the repository and install dependencies:
   ```bash
   flutter pub get

```

2. Run code generation for Drift database models:
```bash
dart run build_runner build --delete-conflicting-outputs

```


3. Run the application:
```bash
flutter run

```



---

## Project Structure

```
lib/
├── core/
│   ├── localization/      # Persian/English localization strings
│   ├── providers.dart     # Riverpod DB and query stream providers
│   └── services/          # Notification scheduling & background actions
├── data/
│   └── database/          # Drift database definitions & migrations
└── features/
    ├── bowel/             # Bristol stool scale & encopresis logging
    ├── enuresis/          # Dry-night calendar & streak tracker
    ├── reports/           # PDF generation & CSV export handlers
    └── voiding/           # Daytime voiding timers & event logger

```

---

## Notification Permissions (Android 13+)

Ensure the following permissions are configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

```
