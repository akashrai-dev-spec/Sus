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

**Sus** is a multiplayer social deduction game. The project contains three parts:
1. **Web App (`web/`)**: Browser-based game built with Next.js and Tailwind CSS. Supports pass-and-play and online rooms with real-time Socket.IO.
2. **Flutter App (`app/`)**: Client for Linux, Android, and iOS.
3. **Game Server (`server/`)**: Fast TypeScript server running on Node.js with Socket.IO and Argon2 PIN hashing.

Players are assigned roles secretly. Normal players receive a secret word, while the imposter receives only the category. Players take turns giving short clues. Normal players try to catch the imposter, while the imposter bluffs to blend in and tries to guess the word before getting caught.

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

### Option 1: Play in Browser (Zero Install)
Run the web app locally:
```bash
cd web
npm run dev
```
Open [http://localhost:3001](http://localhost:3001) in your browser. Choose **Local** for pass-and-play on one device, or **Online** to host a PIN-protected room.

### Option 2: Play on Flutter (Local Offline)
Run the mobile or desktop client:
1. Launch the app (`flutter run -d linux` or mobile).
2. Select **Play** on the home screen.
3. Choose **Create a game** > **Local**.
4. Enter player names and pass the device around to view role cards.

### Option 3: Install on Android
- Follow the [**Android APK Build & Install Guide**](docs/BUILD_APK.md).
- Run `flutter build apk --release` to build your `.apk`.

### Option 4: Deploy the Server
- Follow the [**Production Server Hosting Guide**](docs/HOSTING.md).
- Ready for one-click deployment on **Render** or **Vercel**.

---

## How to Play

### Setup
1. **Join a Room**: 3 to 12 players gather in an online room or pass around one phone in local mode.
2. **Secret Roles**:
   - **Normal Players**: Receive both the secret word and category.
   - **Imposters**: See only the category. They do not know the secret word.

### Game Flow
1. **Clue Rounds**: Players take turns in a set speaking order, giving one short clue about the secret word.
   - Normal players give clues that hint at the word without making it obvious.
   - Imposters listen, bluff during their turn, and try to deduce the word.
2. **Accusations**:
   - Any player can accuse another player during discussion.
   - The game pauses to reveal the accused player's true role.
   - **Imposter Caught**: The imposter is eliminated. If all imposters are eliminated, normal players win.
   - **Innocent Accused**: In games with 4 or more players, the accuser loses their accusation privilege for the rest of the game.
   - **3-Player Role Reversal**: In 3-player games, a wrong accusation does not eliminate the innocent player. Instead, roles reverse: the game picks a new imposter, selects a new secret word, shows each player their new role in an on-screen card, and restarts discussion from the accuser.
3. **Imposter Guess**:
   - The imposter can guess the secret word at any time during discussion.
   - The guess is case-insensitive, ignores extra spaces and punctuation, and ignores leading articles like "a", "an", or "the".
   - A correct guess wins the game on the spot for the imposter.
4. **Final Vote**:
   - If discussion rounds finish without catching the imposter, remaining players cast a final vote. A wrong vote hands victory to the imposter.

### Room Management & Fair Play
- **Minimum 3 Players**: If someone disconnects or leaves mid-match and drops the room below 3 players, the game pauses and returns everyone to the lobby so another player can join.
- **Host Controls**: The room host can kick or permanently ban disruptive players from the lobby before the match begins.

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

### Recommended Platform: [Render](https://render.com) or [Vercel](https://vercel.com)

#### Option A: Deploy on Vercel (Multi-Service Project)
This repository is configured with a root [`vercel.json`](vercel.json) that deploys the Next.js frontend (`web`) and containerized Socket.IO backend (`server`) as a single unified Vercel project:
1. Import this repository into [Vercel](https://vercel.com).
2. Vercel automatically detects the multi-service layout from `vercel.json`.
3. Edge rewrites route `/socket.io/(.*)` directly to the backend container while serving Next.js on `/(.*)`.
4. Run locally with runtime service bindings:
   ```bash
   vercel dev
   ```

#### Option B: Deploy on Render (Free Tier Blueprint)
Render offers a **free tier**, full **WebSocket/Socket.IO** support, free **HTTPS/SSL**, and automatic redeployments on every `git push`.

Because this repository contains a [`render.yaml`](render.yaml) blueprint, you can deploy in minutes:
1. Log in to [render.com](https://render.com).
2. Click **New +** > **Blueprint**.
3. Select your GitHub repository (`Sus`).
4. Click **Apply**!

👉 Read the full [**Production Hosting Guide**](docs/HOSTING.md) for complete details on Vercel, Render, Railway, and VPS / Docker deployments.

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
