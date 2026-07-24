# Cinematic Story Schema v2 — backend contract

The reference sample is [`cinematic_story_v2_hare_and_tortoise.json`](cinematic_story_v2_hare_and_tortoise.json)
in this folder. It is parsed byte-for-byte in a Flutter contract test
(`test/features/learn/cinematic_story_v2_sample_test.dart`), so **if the backend
follows that file's shape, the app will play it.** The app-side model + parser is
`lib/src/features/learn/data/cinematic_story_v2.dart`; the design rationale is in
[`docs/cinematic_story_redesign.md`](../docs/cinematic_story_redesign.md).

## Core idea

A **scene is a timeline**, not a slide. It carries an ordered `cues[]` list of
timestamped beats. The app plays them on a clock; the child just watches. All
`interaction` cues are **optional and non-blocking** — they never gate scene
advance.

## Golden rules for the backend / AI author

1. **Emit script + enums only.** Text (`narration`, `dialogue.text`), timestamps,
   and the closed enum values below. **Never invent asset URLs** — an
   asset-resolver step maps `kind`→optional art *after* generation. This keeps
   every story playable offline from the enum baseline.
2. **Enums are closed but forgiving.** Any unknown enum value degrades to a safe
   default on the client (see the fallbacks below); unknown `cue.type` values are
   silently skipped. So you can ship new vocabulary before the app supports it —
   old apps won't crash, they'll just ignore what they don't know.
3. **Every field except the required core is optional.** Omit `camera`, `audio`,
   `stage.layers`, `particles`, `marks`, `assetManifest` freely — the app fills
   safe defaults.
4. **Timestamps (`t`) are seconds from scene start.** Cues may arrive unsorted;
   the app sorts them. `hold.duration` and `minDuration` extend the scene floor;
   interaction cues never do.

## Required fields

- Story: `id`, `slug`, `title`, `lang`, `ageBand`, `moral`, `scenes[]`.
- Scene: `id`, `title`, `narration` (string **or** `{text, marks, granularity}`).
- Cue: `type`, `t` (+ the per-type fields below).

## Closed enum vocabularies (value → fallback if unknown)

| Field | Allowed wire values | Fallback |
|---|---|---|
| `background` | `hot_day, forest, night, pond, village, sky, rain` | `sky` |
| `mood` | `cheerful, calm, tense, triumphant, tender, sleepy, mysterious` | `calm` |
| `timeOfDay` | `dawn, morning, noon, afternoon, dusk, night` | `morning` |
| `weather` | `clear, cloudy, rain, snow, windy, fog` | `clear` |
| `lighting` | `warm, cool, golden, moonlit, overcast` | `warm` |
| `stage.renderer` | `auto, vector, image, rive, lottie, spine, sprite` | `vector` |
| `cast[].kind` | `crow, rabbit, turtle, lion, mouse, elephant, monkey, dog, cat, bird` | `bird` |
| `cast[].emotion` | `neutral, happy, proud, worried, sad, scared, kind, sleepy, surprised, determined` | `neutral` |
| `prop kind` | `sun, cloud, tree, pot, pond, house, rock, bush, mountain, flower, star, moon` | `cloud` |
| `particles[]` | `sun_rays, wind, birds, leaves, rain, stars, bubbles` | *(skipped)* |
| `camera.ease` | `linear, easeIn, easeOut, easeInOut, easeInOutSine, easeOutBack` | `easeInOut` |
| `transition.type` | `cut, fade, dissolve, slide, iris_in, iris_out, whip_pan, page_turn` | `fade` |
| `music.track` | `forest, calm, playful, night` | `calm` |
| `cue.type` | `dialogue, character, prop, camera, sfx, music, ambient, hold, caption, interaction` | *(skipped)* |
| `character action` | `idle, fly, hop, walk, run, bounce, jump, laugh, cry, sleep, nod, shake, fall, celebrate` | `idle` |
| `interaction.trigger` | `tap, drag` | `tap` |

Free-form strings (not enums, no fallback needed): `sound` (SFX name — app maps
to its `Sfx` enum, defaulting to a chime), `ambience.bed`, `interaction.reaction`,
`cast[].facing` (`left`/`right`), `cast[].entrance.from` (`left`/`right`/`top`/`bottom`),
`cover.palette[]` (hex strings), `concepts[]`, `learningObjective`.

## Cue shapes

```jsonc
{ "type": "dialogue",   "t": 3.0, "speaker": "hare", "text": "...", "emotion": "proud", "duckMusicDb": -6 }
{ "type": "character",  "t": 2.6, "target": "hare", "action": "run" }
{ "type": "prop",       "t": 1.0, "target": "gate", "action": "appear" }
{ "type": "camera",     "t": 4.0, "move": { "from": {...}, "to": {...}, "duration": 3, "ease": "easeInOut" } }
{ "type": "sfx",        "t": 6.2, "sound": "giggle", "volume": 0.8 }
{ "type": "music",      "t": 3.0, "track": "playful", "volume": 0.7 }
{ "type": "ambient",    "t": 0.0, "bed": "pond", "volume": 0.4 }
{ "type": "hold",       "t": 7.0, "duration": 1.5 }
{ "type": "caption",    "t": 2.0, "text": "...", "duration": 2 }
{ "type": "interaction","t": 0.0, "trigger": "tap", "target": "butterfly", "reaction": "sparkle", "sound": "twinkle", "optional": true }
```

## Camera keyframe

```jsonc
"camera": {
  "from": { "target": "hare", "zoom": 1.0, "offset": [0, 0] },   // target optional; offset = fraction of stage [dx, dy]
  "to":   { "target": "hare", "zoom": 1.35, "offset": [0.05, -0.03] },
  "duration": 5, "ease": "easeInOutSine", "startAt": 1.5
}
```

## Delivery notes (for the API layer)

- Split a light **library card** (`slug, title, cover, ageBand, concepts,
  estimatedDuration, premium`) from the full **director track** fetched on open.
- Language is a query param (`?lang=hi`): same `slug`, swap only text/`marks`/
  `voicePack`; enums + layout are shared.
- Assets (when you add them) are immutable + content-hashed; list them in
  `assetManifest[]` (`id, type, url, bytes, v`) so the app can preload/download.
