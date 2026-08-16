# BodySync

BodySync is a Flutter app for tracking weight, calories, and workouts. You log your food, weigh-ins, and workout days as you go through the day, and the app turns that into trends and progress charts — with your data synced to the cloud so it follows you across devices.

## Features

- **Today dashboard** — a single view of the current day: calories, macros, weight, and workout status.
- **Food logging** — search a bundled food database, save your own custom foods, quick-add calories, and reuse recent entries. Charts visualize calorie and macro (protein / carb / fat) intake over time.
- **Body tracking** — weigh-in and body-measurement check-ins, with history and trend charts.
- **Workout calendar** — mark workout days on a monthly calendar at a glance.
- **Cloud sync** — sign in with Firebase Auth; entries are stored locally first and synced to Cloud Firestore, so the app works offline and across devices.
- **Reminders** — local notifications to keep daily logging on track.
- **Data export / import** — back up your data to a file and restore it later.
- **Light and dark themes**, localized strings, and an onboarding flow for first-time setup.

## Getting started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (Dart SDK ≥ 3.4) — verify with `flutter doctor`.
- For iOS: a Mac with [Xcode](https://developer.apple.com/xcode/) and CocoaPods installed, and the command line tools selected:
  ```bash
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  ```
- For Android: Android Studio with an emulator or a connected device.

### Install

Clone the repository and fetch dependencies:

```bash
git clone https://github.com/mehrnazsadrol/body-sync.git
cd body-sync
flutter pub get
```

For iOS, also install the native pods:

```bash
cd ios && pod install && cd ..
```

### Firebase setup

The app initializes Firebase (Auth + Cloud Firestore) at startup. This repository includes a working `lib/firebase_options.dart` and platform config files, so it runs as-is. If you fork the project and want your own backend, point it at your own Firebase project:

1. Create a project in the [Firebase console](https://console.firebase.google.com/) and enable **Authentication** and **Cloud Firestore**.
2. Install the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) and run:
   ```bash
   flutterfire configure
   ```
   This regenerates `firebase_options.dart` and the platform config files for your project.

### Run

List available devices, then run on the one you want:

```bash
flutter devices
flutter run            # runs on the default/connected device
flutter run -d <id>    # runs on a specific device from the list
```

To use the iOS Simulator, start it first with `open -a Simulator`, then run `flutter run`. To run on a physical iPhone, connect it by cable and select it with `flutter run -d <id>`.
