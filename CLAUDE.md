# CLAUDE.md — BrightMind Kids

Project memory for Claude Code. Read this fully before editing. Follow the
conventions in **House Rules** exactly — they are not optional.

---

## 1. What this app is

**BrightMind Kids** — "Play. Color. Grow." A coloring + brain-games app for
children aged **2–8**, built in **Flutter**. Two pillars:

- **Coloring Studio** — tap-to-fill line-art pictures (the hero interaction).
- **Brain Games** — seven mini-games split across age bands 2–4 and 5–6.

Monetization: freemium with a RevenueCat subscription ($6.99/mo, $49/yr,
7-day trial). Audiences: parents (consumer) and schools (B2B, later phase).

This is **Phase 1 (MVP)**. Ship coloring + 5 games + subscription, validate
retention, then expand.

---

## 2. Tech stack

- **Flutter** ≥ 3.27, **Dart** SDK ≥ 3.6 (we use the `Color.withValues` API).
- **State:** Riverpod (`flutter_riverpod`, `riverpod_annotation`). No `setState`
  for business logic. No `Provider`/`Bloc`.
- **Navigation:** `go_router` — single typed route table in `core/router`.
- **Persistence:** Hive CE (`hive_ce`, `hive_ce_flutter`). No backend in Phase 1.
- **L10n:** Flutter `gen-l10n` + ARB files. English + Hindi.
- **Monetization:** `purchases_flutter` (RevenueCat).
- **Media:** `audioplayers` (pooled SFX), `rive` (vector animation).
- **Type:** `google_fonts` Fredoka.
- **Lints:** `flutter_lints` + `custom_lint` + `riverpod_lint`, strict analyzer.

---

## 3. Architecture — MVVM + feature-first

This follows Flutter's official 2026 recommendation. **Separation of concerns
is the top priority.**

```
lib/
  main.dart                       # Hive init, ProviderScope, portrait lock
  src/
    app/app.dart                  # MaterialApp.router + theme + l10n delegates
    core/
      theme/   app_colors.dart    # palette (Figma-derived) — single source of truth
               app_theme.dart     # Material 3 theme, Fredoka type
      router/  app_router.dart     # go_router config + Routes constants
               locale_controller.dart  # runtime language override (Riverpod)
      storage/ widgets/ constants/
    l10n/      app_en.arb app_hi.arb   # + generated app_localizations.dart
    features/
      <feature>/
        data/         # models + repositories (source of truth)
        view_model/   # Riverpod Notifiers: immutable state + intent methods
        view/         # widgets ONLY — no business logic
        engine/       # (coloring only) the CustomPainter render layer
```

### Layer rules (enforce these)

- **view/** — widgets only. Reads view-model state via `ref.watch`, calls intent
  methods via `ref.read(provider.notifier)`. **No logic, no direct data access.**
- **view_model/** — Riverpod `Notifier`/`FamilyNotifier`. Holds **immutable**
  state classes (use `copyWith`). Exposes intent methods (`undo()`, `tapAt()`).
- **data/** — models (`@immutable`, often `Equatable`) and repositories.
- Dependencies point inward: view → view_model → data. Never the reverse.

---

## 4. House Rules (MUST follow)

1. **Localize everything.** No hardcoded user-facing strings. Add a key to
   BOTH `app_en.arb` and `app_hi.arb`, then `flutter gen-l10n`. Access via
   `AppLocalizations.of(context)`. Parameterized strings use ICU placeholders.
2. **Colors come from `AppColors`.** Never inline `Color(0x...)` in widgets.
3. **Performance first.**
   - Wrap custom-painted/animated surfaces in `RepaintBoundary`.
   - `CustomPainter.shouldRepaint` uses cheap identity/length checks, never deep
     compares.
   - `const` everywhere possible (lints enforce it). Target < 16ms frames.
4. **State is immutable.** New state object per change so Riverpod + `shouldRepaint`
   detect changes by identity.
5. **No fail states in games.** No timers, no lives, no "wrong" screens. Wrong
   taps get a gentle wobble + encouraging voice line. Every finish is a win.
6. **Lints are strict.** Single quotes, trailing commas on multiline, explicit
   return types, `prefer_const_*`. Run `flutter analyze` before committing.
7. **Compliance is a launch blocker** (see §7). Parent gate before paywall/
   settings/links. No data collection from kids. No ads. Secrets never committed.
8. **Don't commit generated files.** `app_localizations*.dart`, `*.g.dart` are
   gitignored and regenerated.

---

## 5. Commands

```bash
flutter pub get            # also triggers gen-l10n (generate: true)
flutter gen-l10n           # regenerate localization class
dart run build_runner watch -d   # codegen for Riverpod/Hive during dev
flutter analyze            # MUST pass before commit
flutter test               # unit/widget tests
flutter run                # run on device/simulator
```

> A fresh clone won't compile until `flutter pub get` + `flutter gen-l10n` run,
> because the localization class is generated. This is expected.

---

## 6. Current status

### Done
- Project scaffold, theme, router, localization (en + hi), runtime locale switch.
- All 12 screens exist (some are functional placeholders).
- **Coloring Studio — complete vertical slice:**
  - `features/coloring/data/coloring_template.dart` — `ColorRegion`,
    `ColoringTemplate`, `CanvasFit` (screen↔logical coordinate mapping).
  - `features/coloring/data/coloring_templates.dart` — 4 original vector
    pictures (sun, fish, flower, house) in a 100×100 viewBox. No external assets.
  - `features/coloring/engine/coloring_painter.dart` — draws fills → strokes →
    outlines → details under one canvas transform.
  - `features/coloring/view_model/coloring_view_model.dart` — `CanvasTool`
    (fill/brush/eraser), `CanvasState` (fills map + strokes + history),
    unified undo (`sealed CanvasAction`).
  - `view/coloring_canvas_screen.dart` (tap-to-fill + tools + palette + celebration),
    `view/coloring_gallery_screen.dart` (line-art previews + free/locked badges +
    Free / By-Number mode toggle).
  - **Color-by-Number** variation: `data/by_number_palette.dart`,
    `engine/color_by_number_painter.dart`, `view_model/color_by_number_view_model.dart`,
    `view/color_by_number_screen.dart`. Each template carries a `byNumber` map
    (regionId → palette number); pick a number, tap matching regions, no-fail.
- **Games shared layer:** `games/shared/game_scaffold.dart` (back + progress
  stars + instruction banner), `game_celebration.dart` (shared win overlay,
  shows the earned sticker), `shape_view.dart` (`ShapeKind` enum + painter,
  reused by Shape Sorter, Pattern Sequence and Odd-One-Out).
- **Seven brain games**, all on the shared scaffold (round-based, no-fail):
  1. **Shape Sorter** (2–4) — drag shapes into matching holes.
  2. **Color Match** (2–4) — "Tap everything {color}!".
  3. **Memory Flip** (2–4 & 5–6) — flip-card pairs.
  4. **Odd-One-Out** (2–4) — "Which one is different?", grid grows per round.
  5. **Letter Trace** (5–6) — finger-trace guide dots.
  6. **Count & Tap** (5–6) — "Tap {count} apples!".
  7. **Pattern Sequence / "What's Next?"** (5–6) — continue the AB/ABC/AABB run.
- **Rewards (real, persisted):** `features/rewards/` — 24-emoji `kStickers`
  catalog, `RewardStore`/`HiveRewardStore` (box `rewards`), `RewardsViewModel`
  (`awardRandom`/`awardById`), `win_celebration.dart` (`celebrateWin` = award +
  celebrate). Every game and the coloring "Done!" award a sticker; Sticker Room
  + Home read live counts. Hive store injected via `ProviderScope` override.
- **Daily streak (persisted):** `features/streak/` — `StreakStore`/
  `HiveStreakStore` (box `streak`), `StreakViewModel.recordVisit()` called once
  on Home appear. Same-day reopen no-ops, next day extends, a gap resets to 1.
- **Child profile (persisted) + onboarding:** `features/profile/` — `Buddy`
  catalog (`kBuddies`, original emoji characters — no licensed IP), `AgeBand`,
  `ChildProfile`, `ProfileStore`/`HiveProfileStore` (box `profile`),
  `ProfileViewModel` (`completeOnboarding`/`setAgeBand`/`deleteProfile`) +
  `buddyProvider`. Onboarding screen collects name + age band + buddy and saves
  it; Splash skips onboarding when a profile exists. Home shows the real name +
  chosen buddy and surfaces age-appropriate content (daily pick, play count);
  Games Hub leads with the child's band; the chosen buddy claps in every win
  celebration (`game_celebration.dart`). Store injected via `ProviderScope`.
- **AI foundation (`core/services/`):** `api_client.dart` (`ApiClient` seam +
  Phase-1 `OfflineApiClient` — the app never calls a model API directly, every
  call goes through the future proxy) and `feature_flags.dart` (`FeatureFlags` +
  `FeatureFlagStore`/`HiveFeatureFlagStore` box `feature_flags`, keyed by
  `FeatureFlagKeys`; `adaptiveDifficulty` on, backend/AI-proxy flags off until
  built). Unlike the persistence stores that throw to force injection, the flag
  + adaptive stores default to in-memory so the app/tests work without Hive;
  `main()` injects the Hive-backed versions for persistence.
- **On-device adaptive difficulty (`features/adaptive/`, Tier 2 — free,
  private):** `data/difficulty.dart` (`GameId`, `DifficultyLevel`, pure
  `DifficultyPolicy` heuristic — 0..1 skill, clean rounds raise it, struggles
  ease it, junior age band capped below hard), `data/adaptive_repository.dart`
  (`AdaptiveStore`/`HiveAdaptiveStore` box `adaptive`), `view_model/
  adaptive_view_model.dart` (`AdaptiveViewModel.difficultyFor`/`recordRound`).
  Games read difficulty point-in-time (`ref.read`, no rebuild) when building a
  round and report the round outcome on finish, all gated by the
  `adaptiveDifficulty` flag. **Wired so far:** Odd-One-Out (consumes difficulty
  → grid size + color-vs-shape subtlety; reports a struggle on mis-taps) and
  Count & Tap (consumes difficulty → target range + decoys; reports clean
  rounds). The other five games can adopt the same two-line pattern.
- **Tests:** unit view-model tests for Pattern, Odd-One-Out, Rewards, Streak,
  Profile, plus the adaptive policy + view-model under `test/features/...`
  (44 tests).
- **Cinematic story player is illustration-first:** scenes/stories carry
  optional backend `image`/`coverImage` URLs (`cached_network_image`, disk
  cache, `core/widgets/remote_illustration.dart`); loaded art plays full-bleed
  under the Ken Burns camera with a bottom scrim + hotspot rings, and the
  upgraded procedural vector stage (parallax hills, sun glow, contact shadows,
  vignette) is the always-works offline fallback. Sample wire JSON lives in
  `features/learn/data/sample_cinematic_story.dart` + `backend_samples/`
  (currently served TEMP in place of the backend fetch).

### In progress / pending (next work)
- Adopt adaptive difficulty in the remaining five games (same `_difficulty()` +
  `recordRound` pattern as Count & Tap / Odd-One-Out).
- Real **parent gate** modal (math question) guarding paywall + settings + links.
- **RevenueCat** wiring (entitlement `premium`, paywall purchase/restore).
- Sticker book **drag-to-place** (earned-set persistence is done; arrangement is not).
- Widget tests for screens (view-model units exist).
- Real assets: audio SFX/voice (blocks a sound-matching game), Rive celebrations.

---

## 7. Compliance (non-negotiable)

- **Parent gate** (simple math question) before: paywall, settings, any external
  link, store-review prompt.
- **COPPA / GDPR-K:** no personal data collected from children. Child name stays
  on-device (Hive). No behavioral ads. No fingerprinting/analytics SDKs that
  identify kids. If adding analytics, anonymous aggregate only.
- **Apple Kids Category:** declare age band, no third-party ads, privacy policy URL.
- **Secrets** (RevenueCat keys, signing) live in `.env` / `key.properties` —
  never committed. `.gitignore` already covers these.

---

## 8. Conventions cheat-sheet

- New feature → make `data/`, `view_model/`, `view/` folders under
  `features/<name>/`.
- New screen → add a `Routes.x` constant + `GoRoute` in `app_router.dart`.
- New provider → `final fooProvider = NotifierProvider<FooVM, FooState>(FooVM.new);`
  (or `.family` when keyed, like the coloring canvas is keyed by template id).
- Immutable state class with `copyWith`; expose `bool get isComplete` /
  `int get progress` style getters for the view.
- Game screens: `ConsumerWidget`, use `ref.listen(provider, ...)` to fire
  `showGameCelebration` when `isComplete` flips false→true; `onPlayAgain` calls
  the view-model's `reset()`.

---

## 9. Design reference

- Figma (Phase 1 screens + prototype): file key `oytQpgeXu01S8pwmQiT7LA`.
- Figma (onboarding flow — Splash, Welcome, 3-slide carousel, Profile Setup):
  file key `oSqYkvClGfdzJ4YL2PeEuM`, page "Little_genius application". Source
  of the `assets/images/onboarding/` illustrations and the "Little Genius"
  in-app wordmark (`assets/logos/splash-logo.png`, `app-logo.png`) — the
  formal app/store name stays **BrightMind Kids** (§1); "Little Genius
  Islands" is the in-universe wordmark shown on the splash/welcome screens.
- Color palette mirrored in `app_colors.dart`: coral `#FF7361`, teal `#2EBDB5`,
  yellow `#FFCC40`, purple `#8C73F2`, cream `#FFF7EB`, dark `#332E40`,
  indigo `#414FE0`, crimson `#DF1A1D` (onboarding-flow accents).
- Tone: big rounded tap targets, bold playful type, high contrast, portrait only.

### Design language — "pastel clay" (use for ALL new screens)

Established across the onboarding flow and now applied app-wide (home, hubs,
games, learn, coloring, creative, stickers, settings, paywall, dialogs).
Shared widgets live in `core/widgets/clay_decor.dart` (`ClayBackground`,
`ClayCard`, `ClayTile`, `ClayButton`, `ClayIconButton`, `ClayHeader`,
`pastelOf`, `clayTitle`/`clayBody` text helpers);
`features/onboarding/view/onboarding_decor.dart` just re-exports it:

- **No plain white screens.** Every screen sits on `ClayBackground` (or
  the same recipe): a vertical pastel gradient of a single palette tint fading
  into `AppColors.cream`, with soft scattered decor (4-point sparkles, low-alpha
  bubbles, white cloud blobs) painted behind a `RepaintBoundary`.
- **Pastels are derived, never hardcoded:** `pastelOf(tint, strength)` =
  `Color.alphaBlend(tint.withValues(alpha: strength), Colors.white)`. All hues
  come from `AppColors`; no new hex values.
- **Screen tints so far:** Splash = teal, Welcome = yellow, carousel slides =
  teal → purple → coral (background `Color.lerp`s continuously with the
  `PageController` offset), Profile Setup = purple, Home = blue, Games Hub =
  purple (each game tints by its `GameInfo.color` via `GameScaffold.accent`),
  Learn Hub = green (Story = coral, ABC = teal, Poems = purple), Coloring =
  coral (By-Number = teal), Creative = pinkDeep, Sticker Room = yellow,
  Settings = indigo, Paywall = crimson. The cinematic story player stays dark/
  immersive on purpose. Pick one palette tint per new screen and keep
  neighbors in a flow visually distinct.
- **Claymorphism cards:** hero art and content panels go in `ClayCard` —
  radius 28, pastel fill, 2.5px white border, soft tinted drop shadow
  (`offset (0, 10)`, blur 18). Form sections sit on white rounded-24 cards
  with a soft tinted shadow (see `_SectionCard` in `profile_setup_screen.dart`).
- **CTAs:** `ClayButton` — full-width, radius 24, solid palette fill, hard
  darker bottom-edge shadow + soft glow, white Nunito w800 label, optional
  trailing icon. Don't hand-roll new primary buttons.
- **Type scale:** Poppins w600 28–30 titles (`AppColors.ink`, accent line in
  `crimson`), Lexend Deca 16 body (`AppColors.slate`), Nunito w800 buttons.
- **Motion:** playful `Curves.easeOutBack` transitions, progress pills that
  stretch and re-tint to the active theme color, gentle looping bounces.
  Keep animated surfaces in `RepaintBoundary`.

---

## 10. Roadmap

- **Phase 1 (now):** coloring + 5 games + subscription.
- **Phase 2:** parent dashboard, buddy character, daily surprise, offline packs.
- **Phase 3:** school portal + teacher dashboard.
- **Phase 4:** photo-to-coloring, "Doodle Art" (graffiti-style closed-region line
  art), seasonal events.
