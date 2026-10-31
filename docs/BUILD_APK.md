# Building an Android APK for Sus

This guide explains how to generate a standalone Android APK file for **Sus** so you and your friends can install and play the game on any Android phone or tablet.

Even if you are not a developer, you can follow these steps to build and install the app.

---

## Table of Contents

1. [What is an APK?](#what-is-an-apk)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Build Instructions](#step-by-step-build-instructions)
4. [Where to Find Your Generated APK](#where-to-find-your-generated-apk)
5. [How to Install the APK on Your Phone](#how-to-install-the-apk-on-your-phone)
6. [Troubleshooting](#troubleshooting)

---

## What is an APK?

An **APK** (Android Package Kit) is the file format used by Android to distribute and install apps. Installing an APK directly is called "sideloading" and allows you to play the game without needing to publish it to Google Play Store.

---

## Prerequisites

Before building the APK, ensure your computer has the following tools installed:

1. **Flutter SDK** (3.24 or higher):
   - Check if installed: open terminal and run `flutter --version`.
   - If not installed, download from [flutter.dev](https://docs.flutter.dev/get-started/install).

2. **Java Development Kit (JDK 17)**:
   - Linux (Ubuntu/Debian): `sudo apt install -y openjdk-17-jdk`
   - Windows/macOS: Download OpenJDK 17 from [Adoptium / Eclipse Temurin](https://adoptium.net/).

3. **Android SDK / Android Studio**:
   - Install [Android Studio](https://developer.android.com/studio).
   - In Android Studio, open **SDK Manager** and ensure **Android SDK Platform-Tools** and **Android SDK Command-line Tools** are checked.

4. **Accept Android Licenses**:
   Run in your terminal:
   ```bash
   flutter doctor --android-licenses
   ```
   Press `y` to accept all licenses.

---

## Step-by-Step Build Instructions

### Step 1: Open Terminal and Navigate to the App Folder

```bash
cd /path/to/sus-game/app
```

### Step 2: Fetch App Dependencies

```bash
flutter pub get
```

### Step 3: Choose Your Build Command

#### Mode A: Connecting to a Hosted Production Server (Recommended for Online Play)

If you have hosted your server on Render (or Railway / VPS) as described in the [Hosting Guide](HOSTING.md), pass the server URL when building:

```bash
flutter build apk --release --dart-define=SERVER_URL=https://your-server-name.onrender.com
```

#### Mode B: Local / Offline Only

If you only plan to play the **Local Pass-and-Play** offline mode or connect to a local WiFi server:

```bash
flutter build apk --release
```

#### Bonus: Building Smaller APKs (Split per CPU architecture)

Modern Android devices use 64-bit ARM processors. To generate much smaller APKs (~15-20MB instead of a single ~50MB fat APK), run:

```bash
flutter build apk --release --split-per-abi --dart-define=SERVER_URL=https://your-server-name.onrender.com
```
This will produce three targeted APKs:
- `app-arm64-v8a-release.apk` (for all modern Android phones)
- `app-armeabi-v7a-release.apk` (for older 32-bit Android phones)
- `app-x86_64-release.apk` (for Chromebooks and Android emulators)

---

## Where to Find Your Generated APK

Once the build finishes successfully (usually takes 1–3 minutes), the terminal will print:
`✓ Built build/app/outputs/flutter-apk/app-release.apk`

The file is located at:
```
sus-game/app/build/app/outputs/flutter-apk/app-release.apk
```

You can open this folder directly in your system file manager:
- **Linux**: `xdg-open build/app/outputs/flutter-apk/`
- **macOS**: `open build/app/outputs/flutter-apk/`
- **Windows**: `explorer build\app\outputs\flutter-apk\`

---

## How to Install the APK on Your Phone

You can send the `app-release.apk` file to your phone using any of these easy methods:

### Method 1: Google Drive / Cloud Storage (Easiest)
1. Upload `app-release.apk` to your Google Drive, Dropbox, or OneDrive.
2. Open the cloud app on your Android phone.
3. Tap on `app-release.apk` to download and install.

### Method 2: Messaging App (WhatsApp, Telegram, Discord)
1. Send `app-release.apk` as a document file to yourself or your friends in a Telegram "Saved Messages" chat or WhatsApp chat.
2. On the phone, tap the file in the chat to install.

### Method 3: USB Cable Transfer
1. Connect your phone to your PC via USB cable.
2. In the notification bar of your phone, select **File Transfer** (MTP).
3. Copy `app-release.apk` into your phone's **Downloads** folder.
4. On your phone, open the **Files** app, go to **Downloads**, and tap the APK to install.

### Method 4: Terminal via ADB (For Developers)
If your phone has USB Debugging enabled:
```bash
adb install -r app/build/app/outputs/flutter-apk/app-release.apk
```

---

## Enabling "Install Unknown Apps" on Android

The first time you install an APK downloaded outside of Google Play, Android will display a security prompt:

1. Tap **Settings** on the prompt.
2. Toggle on **Allow from this source** (for Chrome, Files, or WhatsApp).
3. Press the back button and tap **Install**.
4. Launch **Sus** from your home screen or app drawer and start playing!

---

## Troubleshooting

### Error: `Android SDK not found`
Run `flutter doctor` to check what is missing. Set the Android SDK path if needed:
```bash
flutter config --android-sdk /path/to/android/sdk
```

### Error: `Java heap space` or Gradle build failure
Run a clean build to clear cached files:
```bash
cd app
flutter clean
flutter pub get
flutter build apk --release
```

### App doesn't connect to the server when installed
- If using an `http://` URL instead of `https://`, Android requires cleartext network permissions. For production, always use `https://` (which Render provides automatically for free).
- Verify the server is online by opening its `/health` endpoint in Chrome on your phone.
