# Architectural Decision Records (ADRs) - Sus

## ADR 001: Monorepo Structure and Responsibilities
- **Status**: Accepted
- **Context**: Sus is a multiplayer social-deduction party game requiring both a rich client app (supporting Linux, Android, iOS) and an authoritative, low-latency multiplayer backend.
- **Decision**: Organize as a unified monorepo with `app/` (Flutter 3.x client), `server/` (Node.js 20+ TypeScript Socket.IO server), `docs/` (documentation, fixtures, screenshots), and root configuration (`Makefile`, `.github/workflows/ci.yml`).
- **Consequences**: Single source of truth for fixtures, protocol schemas, and end-to-end integration testing.

## ADR 002: Dual Engine Implementation with Shared JSON Fixtures
- **Status**: Accepted
- **Context**: Local pass-and-play mode must work 100% offline without network calls or a running server. Online mode must be strictly server-authoritative to prevent cheating or secret leakage.
- **Decision**: Implement the pure game state machine in Dart (`app/lib/engine/`) for Local mode, and an identical mirror in TypeScript (`server/src/game/`) for Online mode. Replay identical scenarios stored in `docs/fixtures/` in both test suites (`flutter test` and `npm test`).
- **Consequences**: Guarantees zero divergence between offline and online game rule enforcement.

## ADR 003: Dedicated Pages for Profile and Rules
- **Status**: Accepted
- **Context**: The user specified that while the prototype initially showed rules and profile in bottom sheets, they must have their own full, dedicated pages in the application.
- **Decision**: Create dedicated routes (`/profile` and `/rules`) alongside slide-over or sheet presentations when summoned from headers, allowing responsive presentation across desktop and mobile.
- **Consequences**: Clearer deep linking, improved focus states, and a commercial-grade user flow.

## ADR 004: Anti-Cheat & Secret Separation in Socket.IO Protocol
- **Status**: Accepted
- **Context**: In social deduction games, malicious clients can inspect websocket packets to discover secret roles or the secret word.
- **Decision**:
  1. The server never includes the secret word or unrevealed player roles in the public `room:state` broadcast.
  2. The secret word is only sent over socket via a unicast `game:role` event specifically to players assigned the 'normal' role.
  3. Imposters receive only `{ role: 'imposter', category: '...' }`.
  4. Unit and integration tests verify that imposter sockets never receive the secret word event or payload.
- **Consequences**: Completely leak-proof architecture.

## ADR 005: Platform Abstraction for Linux Desktop Safety
- **Status**: Accepted
- **Context**: Mobile plugins for haptics, wake-lock, or sound can fail or crash on Linux desktop.
- **Decision**: Wrap all hardware/platform features behind abstract interfaces in `lib/core/platform/`. Provide no-op or desktop-safe implementations selected via `defaultTargetPlatform`.
- **Consequences**: Flutter desktop build on Linux compiles and runs smoothly with zero platform crashes.

## ADR 006: SwipeToConfirm Primary Action Pattern
- **Status**: Accepted
- **Context**: Accidental taps during party games cause major disruption (e.g. prematurely accusing or starting games).
- **Decision**: Standardize all high-consequence primary actions (Play, Create room, Join room, Start game, Seen role, Next speaker, Accuse, Play again) on the `SwipeToConfirm` component. Support drag gestures, keyboard (Enter/Space), and accessibility semantics.
- **Consequences**: Tactile, intentional action design with zero accidental triggers.

## ADR 007: Bundled Static Typography (Inter)
- **Status**: Accepted
- **Context**: The game must function seamlessly offline and on Linux desktop environments without runtime web font downloads or external CDN dependencies.
- **Decision**: Bundle Inter static TrueType fonts (`Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-Bold.ttf`, `Inter-ExtraBold.ttf`) in `assets/fonts/` with explicit weights 400, 500, 700, and 800 defined in `pubspec.yaml`.
- **Consequences**: Deterministic offline font rendering across Linux, iOS, and Android with zero network latency or layout pop-in.

## ADR 008: Dependency Resolution for Analyzer and Riverpod Generator
- **Status**: Accepted
- **Context**: `build_runner` and `riverpod_generator` encountered a transitive dependency conflict between `analyzer` 7.6.0 and `analyzer_plugin` 0.12.0.
- **Decision**: Pinned `analyzer_plugin: ^0.13.0` in `dependency_overrides` within `app/pubspec.yaml`.
- **Consequences**: `dart run build_runner build -d`, `flutter analyze`, and `flutter test` pass with zero analyzer warnings and 100% build success.

## ADR 009: SwipeToConfirm Animated Spring-Back & Drag Cancellation
- **Status**: Accepted
- **Context**: When a user partially dragged the `SwipeToConfirm` knob without reaching the 85% confirmation threshold or canceled the drag, the widget state did not animate back to 0.0 because `_animController` was not wired to an `AnimatedBuilder`, leaving the knob visually stranded in the middle.
- **Decision**: Refactor `SwipeToConfirm` to drive progress directly through `_animController` inside an `AnimatedBuilder`. Attach spring-back animations on drag release (`Curves.easeOutCubic`), drag cancel, and tap events on both the track and the knob.
- **Consequences**: Tactile, fluid interaction where releasing anywhere prior to 85% smoothly bounces the knob back to the origin, eliminating any stuck states.

## ADR 010: Render Infrastructure as Code Blueprint & Universal APK Packaging
- **Status**: Accepted
- **Context**: Multiplayer hosting and mobile app installation needed to be accessible to non-technical users and hosts.
- **Decision**: Provide a `render.yaml` blueprint defining a free Web Service with native WebSocket support and automatic `/health` checks. Document Android APK generation with `--split-per-abi` and custom `--dart-define=SERVER_URL` in dedicated non-tech-friendly guides.
- **Consequences**: 1-click cloud server deployment on Render and seamless standalone APK sideloading without Google Play Store dependency.

