# Sus — Social Deduction Party Game

<p align="center">
  <img src="asset/mask.svg" width="128" height="128" alt="Sus Mask Logo" />
</p>

<p align="center">
  <strong>One word. One imposter.</strong>
</p>

<p align="center">
  <em>A tense, minimalist social deduction party game for 3 to 12 players.</em>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#web-client">Web App</a> •
  <a href="#how-to-play">How to Play</a> •
  <a href="#hosting-the-server">Host on Render</a> •
  <a href="#building-the-android-apk">Build Android APK</a> •
  <a href="#developer-guide">Development</a> •
  <a href="#architecture">Architecture</a>
</p>

---

## Overview

**Sus** is a cross-platform social deduction party game built as a production-quality monorepo featuring:
1. **Next.js Web Client (`web/`)**: Modern responsive web application with zero-install browser play, Web Audio API procedural sound synthesizers, offline pass-and-play, and real-time Socket.IO multiplayer.
2. **Flutter Native Client (`app/`)**: High-performance mobile and desktop app running smoothly on Linux desktop, Android, and iOS.
3. **Socket.IO Backend (`server/`)**: Server-authoritative Node.js + TypeScript engine with leak-proof role isolation and Argon2 PIN protection.

Players are assigned roles secretly: normal players receive a secret word, while the imposter receives only the category. Through round-robin clue giving, tactical bluffing, instant accusations, and high-stakes imposter word guesses, normal players strive to unmask the imposter before the imposter bluffs their way to victory or guesses the secret word!

---

## Visual Showcase

| Home Screen | Pick How to Play | Open Room Browser |
| :---: | :---: | :---: |
| ![Home](docs/screenshots/home_screen.png) | ![Modes](docs/screenshots/mode_screen.png) | ![Rooms](docs/screenshots/rooms_screen.png) |

| Create Game | Profile Customizer | How Sus Works |
| :---: | :---: | :---: |
| ![Create](docs/screenshots/create_game_screen.png) | ![Profile](docs/screenshots/profile_screen.png) | ![Rules](docs/screenshots/rules_screen.png) |

| Secret Role Reveal | Local Pass & Play | Match Results |
| :---: | :---: | :---: |
| ![Role Reveal](docs/screenshots/role_reveal_screen.png) | ![Local Game](docs/screenshots/local_game_screen.png) | ![Results](docs/screenshots/results_screen.png) |

---

## Quick Start

### 🌐 Option 1: Play in Browser (Zero Install)
Play right now in your web browser with zero downloads:
```bash
cd web
npm run dev
```
Open [http://localhost:3001](http://localhost:3001) in your browser. Choose **Local** for pass-and-play on one device, or **Online** to host a PIN-locked multiplayer room!

### 🎮 Option 2: Play Right Now on Flutter (Local Offline)
Want to play on desktop or mobile using Flutter?
1. Launch the app on any device (`flutter run -d linux` or mobile).
2. Select **Play** ››› on the home screen.
3. Choose **Create a game** > select **Local** mode.
4. Add your friends' names and pass the phone around to view your secret role cards!

### 📱 Option 3: Install on Your Android Phone
Want the app installed on your Android device?
- Read the simple [**Android APK Build & Install Guide**](docs/BUILD_APK.md).
- Run `flutter build apk --release` to generate your `.apk`.

### 🚀 Option 4: Host Your Own Multiplayer Server (100% Free)
Want to play online across different houses or cities?
- Read the [**Production Server Hosting Guide**](docs/HOSTING.md).
- We recommend **Render**: deploy the backend server in 1 click with zero devops.

---

## How to Play

### The Setup
1. **Join a Room**: 3 to 12 players gather in an online room or pass around a single device in local mode.
2. **Secret Roles**:
   - **Normal Players**: Know both the **Secret Word** and Category.
   - **Imposters**: Only see the **Category**. They do NOT know the word!

### The Gameplay Loop
1. **Discussion & Clues**: Players take turns in a fixed random speaking order, giving exactly **one clue** about the secret word.
   - Normal players give subtle clues that hint at the word without making it obvious.
   - Imposters listen carefully, bluff their clue to blend in, and try to deduce the secret word.
2. **Instant Accusation**:
   - At any time, a player can slide **Accuse**.
   - The game pauses and the accused player's role is revealed.
   - **Caught Imposter**: The imposter is eliminated! If all imposters are caught, normal players win.
   - **Innocent Player**: The accusation fails and the accuser permanently loses their accusation privilege for the rest of the game!
3. **Imposter Word Guess**:
   - Imposters can attempt to guess the secret word.
   - If an imposter correctly guesses the word, the imposters **win immediately**!
4. **Final Vote**:
   - If all discussion rounds conclude without catching the imposter, the group holds a final vote.

---

## Step-by-Step Execution Guide

### 1. Prerequisites
- **Node.js** (v20 LTS or higher): [nodejs.org](https://nodejs.org/)
- **Flutter SDK** (3.24+): [flutter.dev](https://flutter.dev/)
- **Linux desktop build tools** (only if running natively on Linux):
  ```bash
  sudo apt-get update && sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
  ```

### 2. Setup Dependencies
Clone the repository and install all packages:
```bash
git clone https://github.com/akashrai-dev-spec/Sus.git
cd Sus
make setup
```

### 3. Start the Server Locally
```bash
cd server
npm run dev
```
The server will start listening at `http://localhost:3000`. You can confirm it is running by visiting `http://localhost:3000/health`.

### 4. Run the Flutter App
In a new terminal window:
```bash
cd app
flutter run -d linux
```
*(Or specify `-d chrome` for web, or `-d <device_id>` for connected phones).*

### 5. Run the Next.js Web Client
In a new terminal window:
```bash
cd web
npm run dev
```
Open [http://localhost:3001](http://localhost:3001) in your browser. Both Local Pass-and-Play (100% offline) and Online Multiplayer are ready to play!

---

## Legal & Compliance

Sus is packaged with comprehensive legal disclosures accessible in both the Flutter app (via the home screen footer) and the Web app:
- **Terms of Service**: [`/terms`](web/src/app/terms/page.tsx)
- **Privacy Policy**: [`/privacy`](web/src/app/privacy/page.tsx)
- **Legal Notice & Impressum**: [`/legal`](web/src/app/legal/page.tsx)
- **Game Rules**: [`/rules`](web/src/app/rules/page.tsx)
- **Download Center**: [`/download`](web/src/app/download/page.tsx)

---

## Hosting the Server

Looking for a place to host the server for you and your friends?

### Recommended Platform: [Render](https://render.com)
Render offers a **free tier**, full **WebSocket/Socket.IO** support, free **HTTPS/SSL**, and automatic redeployments on every `git push`.

Because this repository contains a [`render.yaml`](render.yaml) blueprint, you can deploy in minutes:
1. Log in to [render.com](https://render.com).
2. Click **New +** > **Blueprint**.
3. Select your GitHub repository (`Sus`).
4. Click **Apply**!

👉 Read the full [**Production Hosting Guide**](docs/HOSTING.md) for complete details on Render, Railway, and VPS / Docker deployments.

---

## Building the Android APK

You can build a standalone `.apk` file to install on any Android phone without publishing to Google Play:

```bash
cd app
flutter build apk --release --dart-define=SERVER_URL=https://your-server.onrender.com
```

The output file is generated at:
```
app/build/app/outputs/flutter-apk/app-release.apk
```

👉 Read the step-by-step [**Android APK Build & Install Guide**](docs/BUILD_APK.md) for transferring the file and enabling "Install unknown apps" on Android.

---

## Developer Guide

For developers looking to contribute, write tests, or modify the state machine:
- [**Developer & Contribution Guide**](docs/DEVELOPMENT.md): Detailed workflows, code generation, linting, and testing.
- [**Architecture & State Machine**](docs/ARCHITECTURE.md): Deep dive into client and server state machine parity.
- [**Socket.IO Wire Protocol**](docs/PROTOCOL.md): Specification of all `/game` namespace events, schemas, and rate limits.
- [**Design System**](docs/DESIGN.md): Aesthetic tokens, typography, and accessibility guidelines.
- [**Architectural Decisions (ADRs)**](docs/DECISIONS.md): Records of key design and architecture decisions.

---

## Verification & Automated Tests

Run the test suite across both the Flutter client and the Node.js server:

```bash
# Run all tests (unit, widget, integration):
make test

# Run code linters (ESLint + flutter analyze):
make lint

# Compile the standalone Linux executable:
make build-linux
```

---

## License

MIT License. Designed and crafted for social gaming enthusiasts.
See [LICENSE](LICENSE) for details.
