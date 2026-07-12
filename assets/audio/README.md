# Sound effects (SFX)

The app's `AudioService` (`lib/src/core/services/audio_service.dart`) references
the files below. The **code is already wired** — playback is a graceful no-op
until a matching file exists here, so dropping a file in "activates" that effect
with no code change. Voice/speech is generated on-device via text-to-speech, so
no recorded voice files are needed.

| File         | `Sfx` enum value | Played when                                  |
|--------------|------------------|----------------------------------------------|
| `pop.mp3`    | `Sfx.pop`        | Picking a color; shape dropped in its hole   |
| `plop.mp3`   | `Sfx.plop`       | Filling a region while coloring              |
| `chime.mp3`  | `Sfx.chime`      | A correct/matching tap in a game             |
| `flip.mp3`   | `Sfx.flip`       | Flipping a memory card                        |
| `wobble.mp3` | `Sfx.wobble`     | A gentle "not that one" miss (no fail state) |
| `win.mp3`    | `Sfx.win`        | Finishing a game or a coloring picture       |
| `tap.mp3`    | `Sfx.tap`        | Soft generic tap (e.g. eraser)               |

## Requirements

- Format: **MP3** (filenames must match exactly), short (< ~1.5s), normalized.
- Keep them gentle and cheerful — no harsh/alarming sounds (House Rule §5).
- License: **CC0 / royalty-free only**, safe for a kids' app with no attribution
  burden. Keep a note of each source.

## Suggested CC0 sources

- [kenney.nl](https://kenney.nl/assets?q=audio) — UI / casual game audio packs (CC0)
- [mixkit.co](https://mixkit.co/free-sound-effects/) — free SFX
- [freesound.org](https://freesound.org) — filter by CC0 license
