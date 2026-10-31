# Developer & Contribution Guide for Sus

Welcome to the development guide for **Sus**! This document provides all the technical details needed to set up, develop, debug, and contribute to both the Flutter client and the Node.js server.

---

## Architecture Overview

Sus is organized as a monorepo with two primary packages:

```
sus-game/
├── app/       # Cross-platform Flutter client (Linux, Android, iOS, Web)
├── server/    # Authoritative Node.js + TypeScript Socket.IO server
└── docs/      # Specifications, protocols, fixtures, and guides
```

### Key Principles
1. **Zero Client Authority in Online Mode**: The server owns all room state, role assignment, and the secret word bank. Clients submit intents via Socket.IO, which are strictly validated against Zod schemas.
2. **Offline Mode Parity**: A pure Dart state machine (`app/lib/engine`) mirrors the server's TypeScript state machine (`server/src/game`), allowing completely offline Pass-and-Play games on a single phone or laptop.
3. **Platform Safety**: Mobile-only APIs (vibration, haptics, wake locks) are abstracted behind platform-safe interfaces with graceful no-ops on Linux desktop.

---

## Prerequisites

Ensure your development environment meets these requirements:

- **Node.js**: `v20.x LTS` or higher
- **npm**: `v10.x` or higher
- **Flutter**: `3.24+` on the `stable` channel
- **Dart**: `3.5+` (included with Flutter)
- **Linux Desktop Build Tools** (if developing on Linux):
  ```bash
  sudo apt-get update && sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
  ```

---

## Quick Setup

Run the setup shortcut from the root directory:

```bash
make setup
```

Or install each package manually:

```bash
# Setup Node.js server
cd server
npm install

# Setup Flutter app
cd ../app
flutter pub get
```

---

## Running in Development Mode

### 1. Starting the Backend Server

Start the server with hot-reload enabled via `tsx`:

```bash
cd server
npm run dev
```

The server listens on `http://localhost:3000`. You can verify it is running by checking the health endpoint:

```bash
curl http://localhost:3000/health
# Response: {"status":"ok","version":"1.0.0"}
```

### 2. Starting the Flutter Client

To launch the Flutter app on Linux desktop:

```bash
cd app
flutter run -d linux
```

To connect to a custom or remote server during development:
```bash
flutter run -d linux --dart-define=SERVER_URL=http://localhost:3000
```

You can also run on other connected devices:
- **Chrome / Web**: `flutter run -d chrome`
- **Android Device / Emulator**: `flutter run -d <device_id>`

---

## Code Generation

The Flutter application uses `freezed`, `json_serializable`, and `riverpod_generator`. When adding or editing models or Riverpod providers, regenerate the code using:

```bash
cd app
dart run build_runner build -d
```

To watch for file changes automatically:
```bash
dart run build_runner watch -d
```

---

## Running Tests

### Server Tests
The server uses **Vitest** for unit and Socket.IO integration tests:

```bash
cd server
npm test
```

### Flutter Tests
The Flutter client includes pure Dart engine tests, widget tests, and golden screenshot harnesses:

```bash
cd app
flutter test
```

### Monorepo Shortcut
Run all tests across the monorepo in one command:
```bash
make test
```

---

## Code Quality & Linting

We maintain strict zero-warning standards across both codebases:

### Node.js Server
- **Linter**: ESLint with TypeScript strict rules.
- **Formatter**: Prettier.

```bash
cd server
npm run lint
npm run format
```

### Flutter Client
- **Linter**: `very_good_analysis` with zero analyzer warnings.

```bash
cd app
flutter analyze
```

### Monorepo Shortcut
```bash
make lint
```

---

## Building Standalone Executables

### Linux Desktop Release Bundle
```bash
make build-linux
```
The compiled Linux desktop binary is generated at:
`app/build/linux/x64/release/bundle/sus`

### Android Release APK
```bash
cd app
flutter build apk --release
```
See [Building an Android APK](BUILD_APK.md) for detailed deployment steps.

---

## Useful Makefile Commands

| Command | Action |
| :--- | :--- |
| `make setup` | Installs dependencies for both server and app |
| `make server-dev` | Starts the server in watch/reload mode |
| `make app-run-linux` | Runs Flutter on Linux desktop |
| `make test` | Executes both server and Flutter test suites |
| `make lint` | Runs ESLint and `flutter analyze` |
| `make build-linux` | Builds the optimized Linux release executable |
| `make docker-up` | Starts the server in a local Docker container |
