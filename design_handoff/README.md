# Najah.ai — design handoff

**Start here:** give `AGENT_INSTRUCTIONS.md` to your coding agent.

| Path | What it is |
|---|---|
| `AGENT_INSTRUCTIONS.md` | Step-by-step brief for the coding agent (phases, rules, definition of done) |
| `DESIGN_SPEC.md` | Tokens, components, routes table, behavior of every screen, states, motion, accessibility |
| `design/screens/*.dc.html` | The 42 screens as HTML with inline styles: exact layout, sizes, colors and copy (reference only) |
| `flutter/lib/core/theme/` | Ready-to-use `NajahTheme`, colors, spacing, radius, shadows, motion and type scale |
| `flutter/lib/l10n/` | `app_fr.arb` and `app_ar.arb` with the app's copy |
| `flutter/assets/fonts/` | Inter and Cairo, static weights 400/600/700/800 (SIL Open Font License) |
| `flutter/assets/logo/` | Logo SVGs (horizontal, stacked, dark, symbol, wordmark) |
| `flutter/pubspec_additions.yaml` | Font, asset and localization entries to merge into `pubspec.yaml` |

The live, clickable canvas stays the visual reference for anyone reviewing the work. Prices, merchant number and delays are placeholders (`[PRIX]`, `[TOTAL]`, `[NUMÉRO]`, `[DÉLAI]`, `[N]`) to fill from your backend or config.

The `.dc.html` files need the design canvas to render exactly. Opened in a browser alone they may miss the logo image and a few interactive bits, which is fine for reading layout and copy.
