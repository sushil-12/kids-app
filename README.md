# BrightMind Kids 🎨🧠

**Play. Color. Grow.** — a coloring + brain-games app for kids aged 2–8.

Built with Flutter, following the Flutter team's official 2026 architecture
recommendations: **MVVM + feature-first structure**, **Riverpod** for state,
**go_router** for navigation, full **localization** (English + Hindi), and an
**Impeller**-friendly, performance-first coloring engine.

---

## Quick start

```bash
flutter pub get          # also triggers gen-l10n (generate: true)
flutter gen-l10n         # explicit, if your IDE doesn't auto-run it
flutter run              # runs on a connected device / simulator
```

> First build note: the localization class (`lib/src/l10n/app_localizations.dart`)
> and any `*.g.dart` files are **generated** — they're gitignored on purpose and
> created by `flutter pub get` / `flutter gen-l10n` / `build_runner`. A fresh
> clone won't compile until you run the commands above. This is standard Flutter.

For codegen (Riverpod / Hive) during development:

```bash
dart run build_runner watch -d
```

---

## Architecture

```
lib/
  main.dart                      # entry: Hive init, ProviderScope, orientation lock
  src/
    app/app.dart                 # MaterialApp.router + theme + l10n delegates
    core/
      theme/                     # AppColors (from Figma) + Material 3 AppTheme
      router/                    # go_router config + LocaleController (Riverpod)
      storage/ widgets/ constants/
    l10n/                        # app_en.arb, app_hi.arb (generated class output here)
    features/                    # FEATURE-FIRST: each feature owns its layers
      onboarding/  view/ view_model/
      home/        view/
      coloring/    data/ engine/ view/ view_model/
      games/       shared/ shape_sorter/ color_match/ ...
      stickers/ paywall/ settings/
assets/  coloring_pages/ audio/ rive/ images/
```

### Layer rules (MVVM)

- **View** (`view/`) — widgets only. No business logic. Reads view-model state,
  calls intent methods.
- **View-model** (`view_model/`) — Riverpod `Notifier`s holding immutable state
  and exposing intent methods (e.g. `CanvasViewModel.undo()`).
- **Repository / data** (`data/`) — source of truth for content and persistence.
- **Services** — talk to the outside world (RevenueCat, audio, storage).

### Why these choices

| Concern | Choice | Reason |
|--------|--------|--------|
| State | Riverpod | Compile-safe, testable, no `BuildContext` coupling — Flutter's favored modern approach. |
| Navigation | go_router | Declarative, deep-link & web friendly, single route source of truth. |
| Rendering | `CustomPainter` + `RepaintBoundary` | Coloring strokes repaint in isolation; `shouldRepaint` does cheap identity checks to stay under the 16ms frame budget. |
| Persistence | Hive CE | Fast, offline-first, no backend needed in Phase 1. |
| L10n | gen-l10n + ARB | Official Flutter i18n; runtime language switch via `LocaleController`. |

---

## Performance principles applied

- Coloring canvas wrapped in `RepaintBoundary`; painter uses identity-based
  `shouldRepaint` so unrelated rebuilds never repaint the canvas.
- Strokes drawn as one `Path` per stroke to minimise draw calls.
- Undo history capped (bounded memory).
- `const` constructors throughout; strict lints enforce it.
- Portrait-locked, single predictable layout for young users.

---

## Compliance (launch blockers)

- **Parent gate** before paywall, settings, and any external link.
- **COPPA / GDPR-K**: no personal data collected from kids; child name stays
  on-device; no behavioral ads; no fingerprinting SDKs.
- Secrets (RevenueCat keys etc.) live in `.env` / `key.properties` — never committed.

---

## Roadmap

- **Phase 1 (this repo):** coloring studio, 5 brain games, stickers, paywall.
- **Phase 2:** parent dashboard, buddy character, daily surprise, offline packs.
- **Phase 3:** school portal + teacher dashboard.
- **Phase 4:** photo-to-coloring, "Doodle Art" graffiti-style category, seasonal events.
