# Design System - Sus

## Aesthetic Foundation
Sus draws inspiration from Japanese Oni mythology, high-stakes deception, and tension-building minimalism. The central emblem is the crimson oni mask (`mask.svg`). Every visual cue reinforces mystery, focus, and deliberate action.

---

## Color Tokens

| Token | Hex | Dark Mode Usage | Light Mode Usage |
|---|---|---|---|
| `ink` | `#161616` | Main background | Secondary surface |
| `panel` | `#222222` | Cards, input fields, tiles | Main elevated panel |
| `line` | `#333333` | Borders, subtle dividers | Subtle borders |
| `crimson` | `#9A0F28` | Primary brand accent, primary buttons | Primary brand accent |
| `crimsonBright` | `#B5173A` | Progress fill, hover/active states | Hover/active states |
| `bone` | `#F4F4F4` | Primary high-contrast text | Inverted dark text |
| `mute` | `#9A9A9A` | Secondary text, captions, inactive states | Secondary text |
| `ash` | `#D9D9D9` | Neutral buttons (e.g. Learn more) | Secondary action fill |
| `win` | `#6FD08C` | Normal player victory, success badges | Success states |
| `lose` | `#B5173A` | Imposter caught, defeat states | Defeat states |

All color tokens are exposed through Flutter's `ThemeExtension<SusColors>` guaranteeing no hard-coded colors exist in widgets.

---

## Typography (Inter)
Font scale using Inter bundled locally (400, 500, 700, 800):
- **Display**: 40/44 w800 (Screen hero titles, victory headlines)
- **Title**: 26/32 w800 (Section titles, modal headers)
- **Heading**: 20/26 w700 (Card titles, player names)
- **Body**: 16/24 w500 (Body text, clues, input text)
- **Caption**: 13/18 w500 (Labels, subtitle counters, pill badges)

*Rule: Sentence case everywhere. No all-caps labels or decorative eyebrow text.*

---

## Spatial System & Metrics
- **Base Grid**: 4 pt
- **Corner Radii**:
  - Inputs & Segmented Buttons: `10px`
  - Primary Buttons & Sliders: `14px`
  - Cards & Choice Panels: `18px`
  - Bottom Sheets: `24px`
- **Screen Padding**: `22px`
- **Min Tap Target**: `48px` x `48px`
- **Desktop Window Bounds**:
  - Minimum geometry: 360px x 640px
  - Center content column: `maxWidth: 480px`

---

## Signature Components

### 1. `SwipeToConfirm`
The centerpiece interaction. Prevents unintended slips.
- Visual track in `crimson` with white knob containing chevron `›`.
- Dragging animates the fill towards `crimsonBright`.
- Releasing below 85% springs back smoothly with curve `Curves.easeOutBack`.
- Passing 85% triggers execution + haptic pulse.
- Fully accessible with Keyboard `Enter` / `Space` and Semantics actions.

### 2. `RoleCard`
Hold-to-reveal role inspection.
- Default state: subtle dark container with instruction "Hold to reveal".
- On pointer down: reveals role or secret word with privacy blur backdrop.
- On pointer up/cancel: immediately resets to hidden state.

### 3. `OniMask`
Renders vector `mask.svg` with customizable size and crimson tint.

### 4. `PinField`
Four distinct numeric digit boxes supporting smooth focus transfer, keypad input, and shake animation on failure.
