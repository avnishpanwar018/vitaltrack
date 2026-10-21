# VitalTrack

VitalTrack is a Flutter application for recording and reviewing blood-pressure
and pulse readings over time. It is designed for local, offline-first tracking
and supports multiple family profiles.

> **Medical disclaimer:** VitalTrack does not measure blood pressure and does
> not provide medical advice, diagnosis, or treatment. Readings must be entered
> manually or imported from a compatible device. Consult a qualified healthcare
> professional for medical decisions.

## Features

- Dashboard with the latest reading and weekly/monthly averages
- Validated blood-pressure, pulse, weight, symptom, mood, and medication entries
- History search, filters, sorting, edit/delete, pagination, and month grouping
- AHA-style blood-pressure classification
- Statistics and interactive charts for 7-day through 1-year ranges
- Local daily reminders and notification scheduling
- PDF and CSV report generation with sharing/printing
- Multiple family profiles and file attachments
- Pattern-based health insights for informational use only
- PIN lock with privacy cover when the app is backgrounded
- Light, dark, and system Material 3 themes
- Persistent browser storage for the web build

## Technology

- Flutter / Dart with Material 3
- Riverpod for state management
- GoRouter for navigation
- SQLite via `sqflite` on native platforms
- `SharedPreferences`-backed repositories for web persistence
- `fl_chart` for charts
- `pdf`, `csv`, `printing`, and `share_plus` for reports
- `flutter_local_notifications`, `flutter_timezone`, and `timezone` for reminders
- `flutter_secure_storage` and AES encryption support for PIN-related secrets

## Getting started

### Requirements

- Flutter 3.44 or newer is recommended
- Dart 3.12 or newer is recommended
- Android development additionally requires an Android SDK, platform tools,
  and the NDK version selected by the Flutter toolchain

### Clone the repository

```bash
git clone https://github.com/avnishpanwar018/vitaltrack.git
cd vitaltrack
```

### Run locally

```bash
flutter pub get
flutter run
```

For Android, create `android/local.properties` locally with your SDK and Flutter
paths. That file is machine-specific and is intentionally ignored by Git.

### Web

```bash
flutter run -d chrome
```

The web build stores application data in browser local storage. Clearing browser
site data removes those records.

### Checks

```bash
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
```

The Android build may require the local Android SDK/NDK to be installed first.

## Architecture

```text
lib/
├── core/
│   ├── database/          SQLite helper and schema migrations
│   ├── models/            Reading, profile, reminder, and attachment models
│   ├── repositories/      Native SQLite and persistent web repositories
│   ├── providers/         Riverpod providers and application actions
│   ├── services/          Reports, statistics, insights, security, notifications
│   ├── theme/             Material 3 themes and color tokens
│   └── utils/             Router, validators, dates, constants, web helpers
├── screens/               Feature screens
├── widgets/               Shared UI components
└── main.dart              Application entry point and lifecycle handling
```
