# Najah.ai — Instructions for the coding agent

Paste this whole file into your coding agent (Claude Code, Cursor, Copilot agent…) from the root of the Najah Flutter project, with this handoff folder copied into the repo as `design_handoff/`.

---

## Your mission

Implement the Najah.ai mobile UI in this Flutter app so that it matches the design in `design_handoff/`, in French and Arabic (RTL), for students and parents.

The source of truth, in this order:
1. `design_handoff/DESIGN_SPEC.md`: tokens, components, every screen, states, motion, accessibility.
2. `design_handoff/design/screens/*.dc.html`: the exact screens as HTML with inline styles. Read them for layout, spacing, sizes, colors and copy. They are **reference only**: never embed them in the app or use a WebView.
3. `design_handoff/flutter/`: ready-made theme, tokens, fonts and translations to copy into the app.

## Ground rules

- **Read before you write.** Start by exploring the existing project: `pubspec.yaml`, `lib/` structure, state management, routing, API/data layer, existing screens and localization. Reuse what exists. Do not rewrite working business logic or change the backend contract.
- **Match what's already there.** If the project already uses a state-management package (Riverpod, Bloc, Provider, GetX…) or a router, keep it. Only if there is none, use `go_router` and `flutter_riverpod`.
- **No invented backend.** Where an API doesn't exist yet, create a repository interface plus a fake implementation that returns the sample data from the spec, and leave a `// TODO(api):` comment. Never hard-code sample data inside widgets.
- **Placeholders stay placeholders.** Prices, merchant numbers and delays appear as `[PRIX]`, `[TOTAL]`, `[NUMÉRO]`, `[DÉLAI]`, `[N]` in the design. Read them from config or the API, and never invent values.
- **Work in small, reviewable steps.** Follow the phases below. After each phase: `flutter analyze` with zero new warnings, run the app, and give me a short summary of what changed and what's next. Commit per phase if the repo uses git, and do not push unless I ask.
- **Ask when blocked.** If a requirement conflicts with existing code or the backend, stop and ask instead of guessing.

## Phase 0: foundation

1. Copy `design_handoff/flutter/lib/core/theme/*` to `lib/core/theme/`.
2. Copy `design_handoff/flutter/assets/fonts/*` to `assets/fonts/`.
3. Copy `design_handoff/flutter/assets/logo/*` to `assets/logo/`.
4. Add the font and asset entries from `design_handoff/flutter/pubspec_additions.yaml` to `pubspec.yaml`.
5. Wire `NajahTheme.light(locale)` into `MaterialApp`: Inter for French, Cairo for Arabic, same type scale.
6. Set up localization with `flutter_localizations` + `intl` and generated `.arb` files. Copy `design_handoff/flutter/lib/l10n/app_fr.arb` and `app_ar.arb`. Default locale: French. Supported: `fr`, `ar`.
7. Direction comes from the locale automatically. In **every** widget use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `start/end` (never `left/right`). Mirror directional icons (back, chevrons, send) in RTL, but never mirror media controls, math, or numbers.
8. Math expressions (e.g. `(x + 3)²`) are always wrapped in `Directionality(textDirection: TextDirection.ltr)` or use the `\u2066…\u2069` isolates.

## Phase 1: design-system widgets (`lib/core/widgets/`)

Build these first, each with a widget test and golden test in FR and AR:
- `NajahButton`: variants primary, secondary, ink, gold, quiet, danger; states loading and disabled; height 52; radius 12.
- `NajahTextField`: optional `+222` prefix, and focus, error and success hint states.
- `PinBoxes`: boxes for a 4-digit PIN or 6-digit WhatsApp code.
- `PinPad`: a custom keypad (no system keyboard) that works for login, the parent code and focus unlock.
- `NajahCard`: bordered and shadow variants.
- `StatTile`.
- `SubjectCard`: with a `MasteryRing` built with `CustomPainter`. The ring starts at 12 o'clock, runs clockwise in LTR and counter-clockwise in RTL.
- `ProgressBar` (teal) and `XpBar` (gold).
- `JourneyBar`: Vidéo → Leçon → Exercices, with done, active and upcoming steps.
- `NajahChip`: neutral, selected, teal, gold and red status variants.
- `StreakBadge`, and `LevelBadge` (gold square with ink number).
- `NajahSnackbar`: including the offline variant.
- `NajahDialog` (radius 20) and `NajahBottomSheet` (radius 20 top, with drag handle).
- `EmptyState`, `ErrorState` (with retry), and `Skeleton` (shimmer ≤ 1.2 s loop, disabled when reduce-motion is on).
- `OfflineBanner`.
- `FocusModeBar`.
- `NajahTabBar`: student has 4 tabs, parent has 3.
- `VideoPlayerCard` and `PlaylistItem`.

## Phase 2: onboarding

Build the splash, welcome and language switch, student login, parent login, WhatsApp code, registration, trial offer and claim invite screens. Follow the spec section "1. Launch & onboarding" and the routes table.

The language choice persists (e.g. `shared_preferences`) and switches the app live.

## Phase 3: student space

Build these screens:
- Home and subjects.
- The lesson viewer: video, concept with gating mini-quiz, worked example, revision sheet.
- The QCM session and result/streak screen.
- Open practice with AI correction.
- Homework Helper.
- Weekly exams: list, intro, timed session, results.
- Downloads, profile, and the subscription-locked screen.

Every data screen implements **loading (skeleton), empty, error, offline** states as described in the spec.

## Phase 4: focus mode and protected content

- **Screenshots and screen recording:** on Android use `FLAG_SECURE`. On iOS, detect capture (`UIScreen.isCaptured` / `capturedDidChangeNotification`) and show the black "Enregistrement d'écran non autorisé" screen while capture is active. Use an existing maintained plugin if the project allows it, otherwise a small platform channel.
- **Focus mode on the student phone:**
  - Show `FocusModeBar` during active windows.
  - "Déverrouiller" opens a bottom sheet with `PinPad`, checked against the parent PIN (hashed, never stored in plain text).
  - Block logout and account deletion with the friendly dialog.
  - Log "left the app" events via `AppLifecycleState` and "unlocked with code" events.
  - **Android:** use lock-task / screen pinning (`startLockTask`). Without device-owner rights, Android shows a system confirmation, and that's expected.
  - **iOS:** apps can't lock themselves without MDM, so show the Guided Access hint card instead.

## Phase 5: parent space

Build these screens:
- Parent home with children cards.
- Add child, and the add-child success screen.
- Child progress.
- Focus-mode settings.
- Subscription plans with child selection.
- Bankily payment (phone + transaction code), and subscription status (pending, active, expired, refused).

## Phase 6: polish and QA

- **Motion:** add the motion from the spec. Everything is ≤ 400 ms except the ~1.2 s splash. Respect `MediaQuery.disableAnimations`.
- **Accessibility:**
  - Semantics labels on all icon-only buttons.
  - 44 pt minimum touch targets.
  - Test at text scale 1.3 and 2.0: no overflow, and layouts wrap or scroll.
- **Performance on low-end Android:**
  - `const` widgets wherever possible.
  - Cached images, and no heavy shadows in long lists.
  - Pagination for lists.
  - Keep total download size in mind.
- **QA pass:** run through every screen in FR and AR and fix anything that doesn't mirror correctly.

## Definition of done

- [ ] Every screen in the routes table exists and is reachable, in FR and AR.
- [ ] Colors, type, spacing and radius come only from `lib/core/theme/` (no stray hex values in widgets).
- [ ] Loading, empty, error and offline states exist on every data screen.
- [ ] Golden tests for design-system widgets pass in FR and AR, and `flutter analyze` is clean.
- [ ] No sample data inside widgets; placeholders read from config/API.
- [ ] A final summary listing anything not done and every `TODO(api)` left.
