#!/usr/bin/env python3
"""Generate the 7 BrightMind Kids SFX as original, gentle WAV clips.

Pure standard library (no pip installs). Writes 16-bit mono WAVs into
assets/audio/raw/, ready for tool/prepare_audio.sh to normalize + convert to mp3.

These tones are synthesized here, so they are inherently royalty-free / CC0 and
safe for a kids' app. Replace any of them later with a nicer downloaded clip.

Run:  python3 tool/generate_audio.py
"""
from __future__ import annotations

import math
import os
import struct
import wave

SR = 44100  # sample rate

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RAW_DIR = os.path.join(ROOT, "assets", "audio", "raw")


def _adsr(n: int, total: int, attack=0.01, release=0.08) -> float:
    """A soft attack/decay envelope so nothing clicks or sounds harsh."""
    t = n / SR
    dur = total / SR
    a = min(attack, dur / 2)
    r = min(release, dur / 2)
    if t < a:
        return t / a
    if t > dur - r:
        return max(0.0, (dur - t) / r)
    return 1.0


def _tone(freq, dur, vol=0.6, *, glide=0.0, vibrato=0.0, decay=False):
    """One enveloped sine partial. `glide` bends pitch over the note (Hz delta);
    `vibrato` adds gentle wobble; `decay` makes it ring down like a bell."""
    n = int(dur * SR)
    out = []
    phase = 0.0
    for i in range(n):
        frac = i / n
        f = freq + glide * frac
        if vibrato:
            f += vibrato * math.sin(2 * math.pi * 6 * (i / SR))
        phase += 2 * math.pi * f / SR
        env = _adsr(i, n)
        if decay:
            env *= math.exp(-3.5 * frac)
        out.append(vol * env * math.sin(phase))
    return out


def _mix(*layers):
    """Sum equal-length (or padded) layers, then soft-clip to [-1, 1]."""
    length = max(len(l) for l in layers)
    buf = [0.0] * length
    for layer in layers:
        for i, s in enumerate(layer):
            buf[i] += s
    return [max(-1.0, min(1.0, s)) for s in buf]


def _seq(*notes):
    """Concatenate note buffers end to end (for arpeggios/melodies)."""
    buf = []
    for note in notes:
        buf.extend(note)
    return buf


def _write(name: str, samples):
    path = os.path.join(RAW_DIR, f"{name}.wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(struct.pack("<h", int(s * 32767)) for s in samples)
        w.writeframes(frames)
    print(f"  ✓ {name}.wav  ({len(samples) / SR:.2f}s)")


# Note frequencies (a bright, child-friendly upper register).
C5, D5, E5, G5, A5, C6, E6, G6, C7 = (
    523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1318.5, 1568.0, 2093.0,
)


def build():
    os.makedirs(RAW_DIR, exist_ok=True)
    print("Generating SFX → assets/audio/raw/")

    # pop  — quick upward blip: picking a color, dropping a shape in its hole.
    _write("pop", _tone(G5, 0.10, vol=0.7, glide=520, decay=True))

    # plop — soft downward "bloop": filling a region while coloring.
    _write("plop", _tone(G5, 0.16, vol=0.65, glide=-360, decay=True))

    # chime — happy two-note ding: a correct/matching tap in a game.
    _write("chime", _mix(
        _seq(_tone(E6, 0.10, vol=0.55, decay=True),
             _tone(C7, 0.26, vol=0.55, decay=True)),
        # a quiet octave shimmer underneath
        _seq([0.0] * int(0.10 * SR),
             _tone(E6, 0.26, vol=0.18, decay=True)),
    ))

    # flip — short airy swoosh: turning a memory card.
    n = int(0.14 * SR)
    swoosh = []
    seed = 1234567
    for i in range(n):
        seed = (1103515245 * seed + 12345) & 0x7FFFFFFF  # tiny LCG noise
        noise = (seed / 0x3FFFFFFF) - 1.0
        env = _adsr(i, n, attack=0.02, release=0.06) * (0.3 + 0.7 * (i / n))
        swoosh.append(0.4 * env * noise)
    _write("flip", _mix(swoosh, _tone(A5, 0.14, vol=0.2, glide=400)))

    # wobble — gentle low "boing", never alarming: a soft "not that one" miss.
    _write("wobble", _tone(D5, 0.26, vol=0.55, glide=-70, vibrato=22, decay=True))

    # win — cheerful rising arpeggio: finishing a game or coloring picture.
    _write("win", _seq(
        _tone(C5, 0.12, vol=0.6, decay=True),
        _tone(E5, 0.12, vol=0.6, decay=True),
        _tone(G5, 0.12, vol=0.6, decay=True),
        _mix(_tone(C6, 0.45, vol=0.6, decay=True),
             _tone(E6, 0.45, vol=0.3, decay=True)),
    ))

    # tap — very soft, short click: generic tap (e.g. eraser).
    _write("tap", _tone(A5, 0.05, vol=0.4, decay=True))

    print("Done. Now run: ./tool/prepare_audio.sh")


# ── Music loops (cinematic story player) ─────────────────────────────────────
# Four gentle ~9.6s background loops, one per MusicTrack enum value. Written to
# assets/audio/raw/music_<name>.wav; convert to assets/audio/music/<name>.mp3
# with ffmpeg (see the note printed at the end). Loops land on whole notes with
# decaying envelopes so the seam is soft.

C4, D4, E4, F4, G4, A4, B4 = 261.63, 293.66, 329.63, 349.23, 392.0, 440.0, 493.88
A3, C3, E3, G3 = 220.0, 130.81, 164.81, 196.0


def _pad(freq, dur, vol=0.16):
    """A soft sustained tone with slow vibrato — the 'pad' voice for loops."""
    return _tone(freq, dur, vol=vol, vibrato=1.5)


def _pluck(freq, dur, vol=0.3):
    return _tone(freq, dur, vol=vol, decay=True)


def _rest(dur):
    return [0.0] * int(dur * SR)


def _overlay(base, layer, at):
    """Mix `layer` into `base` starting at second `at` (in place)."""
    start = int(at * SR)
    for i, s in enumerate(layer):
        j = start + i
        if j < len(base):
            base[j] = max(-1.0, min(1.0, base[j] + s))
    return base


def build_music():
    os.makedirs(RAW_DIR, exist_ok=True)
    print("Generating music loops → assets/audio/raw/")
    beat = 0.6  # 100 bpm
    bars = 4
    total = beat * 4 * bars  # 9.6s

    # calm — slow C-major arpeggio pad, like a lullaby music box.
    calm = _rest(total)
    pattern = [C4, E4, G4, C5, G4, E4]
    for bar in range(bars):
        for i, f in enumerate(pattern):
            _overlay(calm, _pluck(f, beat * 1.6, vol=0.22), bar * beat * 4 + i * beat * 0.66)
    _overlay(calm, _pad(C3, total, vol=0.08), 0)
    _write("music_calm", calm)

    # forest — pentatonic plucks with little bird chirps on top.
    forest = _rest(total)
    penta = [C4, D4, E4, G4, A4, G4, E4, D4]
    for bar in range(bars):
        for i, f in enumerate(penta):
            _overlay(forest, _pluck(f, beat, vol=0.2), bar * beat * 4 + i * beat * 0.5)
        # a chirp at the top of each bar
        _overlay(forest, _tone(E6, 0.09, vol=0.12, glide=300, decay=True), bar * beat * 4 + beat * 1.5)
        _overlay(forest, _tone(G6, 0.07, vol=0.10, glide=250, decay=True), bar * beat * 4 + beat * 1.72)
    _overlay(forest, _pad(G3, total, vol=0.07), 0)
    _write("music_forest", forest)

    # playful — bouncy staccato major hops, a bit faster feel.
    playful = _rest(total)
    hops = [C5, G4, A4, E4, F4, C5, G4, E5]
    for bar in range(bars):
        for i, f in enumerate(hops):
            _overlay(playful, _pluck(f, beat * 0.45, vol=0.26), bar * beat * 4 + i * beat * 0.5)
    _overlay(playful, _pad(C4, total, vol=0.05), 0)
    _write("music_playful", playful)

    # night — slow A-minor pad with sparse twinkle notes.
    night = _rest(total)
    _overlay(night, _pad(A3, total, vol=0.10), 0)
    _overlay(night, _pad(E4, total, vol=0.06), 0)
    twinkles = [(C6, 1.2), (E6, 3.6), (A5, 6.0), (E6, 8.2)]
    for f, at in twinkles:
        _overlay(night, _pluck(f, 0.9, vol=0.14), at)
    _write("music_night", night)

    print(
        "Done. Convert with:\n"
        "  for t in calm forest playful night; do\n"
        "    ffmpeg -y -i assets/audio/raw/music_$t.wav -codec:a libmp3lame \\\n"
        "      -qscale:a 4 assets/audio/music/$t.mp3\n"
        "  done"
    )


if __name__ == "__main__":
    build()
    build_music()
