#!/usr/bin/env bash
#
# prepare_audio.sh — turn loosely-named downloaded clips into the 7 SFX files
# that BrightMind Kids' AudioService expects (see assets/audio/README.md).
#
# Workflow:
#   1. Download CC0 clips (Pixabay / Kenney / Mixkit / Freesound).
#   2. Drop them in assets/audio/raw/ named after the effect — ANY extension:
#        pop.wav  chime.ogg  win.mp3  flip.m4a  ...
#      (only the part before the dot matters; case-insensitive)
#   3. Run:  ./tool/prepare_audio.sh
#      → converts, trims to <=2s, loudness-normalizes, and writes
#        assets/audio/<name>.mp3 for each one found.
#
# Run with --verify to only report which of the 7 files are present (no convert).
#
# Requires ffmpeg:  brew install ffmpeg
set -euo pipefail

# Resolve repo paths relative to this script, so it works from any CWD.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$ROOT/assets/audio"
RAW_DIR="$OUT_DIR/raw"

# The 7 effects AudioService references (must match Sfx enum filenames).
NAMES=(pop plop chime flip wobble win tap)

green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red() { printf '\033[31m%s\033[0m\n' "$1"; }

verify() {
  echo "SFX files in assets/audio/:"
  local present=0
  for name in "${NAMES[@]}"; do
    if [[ -f "$OUT_DIR/$name.mp3" ]]; then
      green "  ✓ $name.mp3"
      present=$((present + 1))
    else
      yellow "  ✗ $name.mp3 (missing — that effect stays silent)"
    fi
  done
  echo "$present / ${#NAMES[@]} effects active."
}

if [[ "${1:-}" == "--verify" ]]; then
  verify
  exit 0
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  red "ffmpeg not found. Install it first:  brew install ffmpeg"
  exit 1
fi

mkdir -p "$RAW_DIR"

converted=0
for name in "${NAMES[@]}"; do
  # First case-insensitive source match for this effect, any extension.
  src=""
  for f in "$RAW_DIR"/*; do
    [[ -e "$f" ]] || continue
    base="$(basename "$f")"
    stem="${base%.*}"
    shopt -s nocasematch
    if [[ "$stem" == "$name" ]]; then src="$f"; fi
    shopt -u nocasematch
    [[ -n "$src" ]] && break
  done

  if [[ -z "$src" ]]; then
    yellow "skip  $name — no $name.* in assets/audio/raw/"
    continue
  fi

  # Trim to 2s, normalize loudness (gentle, consistent), encode MP3 V4 (~165kbps).
  ffmpeg -hide_banner -loglevel error -y -i "$src" \
    -t 2 -af "loudnorm=I=-16:TP=-1.5:LRA=11" \
    -codec:a libmp3lame -qscale:a 4 \
    "$OUT_DIR/$name.mp3"
  green "ok    $name.mp3  (from $(basename "$src"))"
  converted=$((converted + 1))
done

echo
green "Converted $converted file(s)."
echo
verify
