import 'dart:convert';

import 'cinematic_story_v2.dart';

// ---------------------------------------------------------------------------
// TEMP — sample backend response for the v2 cinematic ("director track") story
// player. Byte-for-byte the wire shape the backend will return; the canonical
// copy the backend team is handed lives at
// backend_samples/cinematic_story_v2_hare_and_tortoise.json (guarded by a
// contract test). Parsing here goes through the same jsonDecode +
// CinematicStoryV2.fromJson path a real response would, so switching to the
// live backend changes nothing else.
//
// English only for now; a Hindi track drops in the same way (swap text +
// marks + voicePack, keep the enums/layout).
// ---------------------------------------------------------------------------

/// The sample v2 story, parsed from raw wire JSON exactly like a backend
/// response. [lang] is accepted for parity with the backend contract; only
/// English is bundled today, so any code returns the English track.
CinematicStoryV2 sampleCinematicStoryV2For(String lang) =>
    CinematicStoryV2.fromJson(
      jsonDecode(_wireJsonEn) as Map<String, dynamic>,
    );

const String _wireJsonEn = '''
{
  "schemaVersion": "2.0",
  "id": "story_hare_tortoise",
  "slug": "hare-and-tortoise",
  "title": "The Hare and the Tortoise",
  "lang": "en",
  "availableLangs": ["en", "hi"],
  "ageBand": "junior",
  "category": "Moral Stories",
  "concepts": ["persistence", "humility", "kindness"],
  "moral": "Slow and steady wins the race.",
  "estimatedDuration": 210,
  "cover": { "emoji": "🐢", "image": null, "palette": ["#2EBDB5", "#FFCC40"] },
  "audio": {
    "music": { "track": "playful", "volume": 0.55, "loop": true },
    "ambience": { "bed": "meadow", "volume": 0.4, "loop": true },
    "voicePack": "warm_female_en",
    "narrationSpeed": 1.0
  },
  "reward": { "stars": 10, "coins": 5, "badgeStickerId": "trophy" },
  "assetManifest": [],
  "scenes": [
    {
      "id": 1,
      "title": "A Sunny Morning",
      "minDuration": 10,
      "background": "village",
      "mood": "cheerful",
      "timeOfDay": "morning",
      "weather": "clear",
      "lighting": "golden",
      "learningObjective": "Meet the characters; feel the calm of the meadow.",
      "stage": {
        "renderer": "auto",
        "image": null,
        "layers": [
          { "z": 0, "props": [ { "id": "hills", "kind": "mountain", "x": 0.5, "y": 0.72, "scale": 2.0 } ] },
          { "z": 1, "props": [ { "id": "tree1", "kind": "tree", "x": 0.15, "y": 0.6, "scale": 1.0 } ] }
        ]
      },
      "cast": [
        { "id": "hare", "kind": "rabbit", "x": 0.32, "y": 0.62, "scale": 1.0, "facing": "right", "emotion": "happy" },
        { "id": "tortoise", "kind": "turtle", "x": 0.66, "y": 0.66, "scale": 0.9, "facing": "left", "emotion": "calm" }
      ],
      "camera": {
        "from": { "zoom": 1.0, "offset": [0, 0] },
        "to": { "zoom": 1.12, "offset": [0.04, -0.02] },
        "duration": 9, "ease": "easeInOutSine", "startAt": 0.5
      },
      "audio": {
        "music": { "track": "playful", "volume": 0.55 },
        "ambience": { "bed": "birds_meadow", "volume": 0.45 }
      },
      "transition": { "in": { "type": "fade", "duration": 0.8 }, "out": { "type": "dissolve", "duration": 0.7 } },
      "narration": {
        "text": "On a golden morning in a green meadow, a quick little hare and a slow, gentle tortoise were the best of friends.",
        "granularity": "word", "marks": []
      },
      "cues": [
        { "type": "character", "t": 2.0, "target": "hare", "action": "hop" },
        { "type": "character", "t": 4.5, "target": "tortoise", "action": "nod" },
        { "type": "interaction", "t": 0.0, "trigger": "tap", "target": "butterfly", "reaction": "sparkle", "sound": "twinkle", "optional": true, "narrateOnMiss": false }
      ]
    },
    {
      "id": 2,
      "title": "The Boast",
      "minDuration": 11,
      "background": "village",
      "mood": "cheerful",
      "timeOfDay": "morning",
      "weather": "clear",
      "lighting": "warm",
      "learningObjective": "Pride: the hare brags.",
      "cast": [
        { "id": "hare", "kind": "rabbit", "x": 0.4, "y": 0.62, "facing": "right", "emotion": "proud" },
        { "id": "tortoise", "kind": "turtle", "x": 0.62, "y": 0.66, "facing": "left", "emotion": "calm" }
      ],
      "camera": {
        "from": { "target": "hare", "zoom": 1.1 },
        "to": { "target": "hare", "zoom": 1.35 },
        "duration": 5, "ease": "easeInOut", "startAt": 1.5
      },
      "transition": { "in": { "type": "dissolve", "duration": 0.7 }, "out": { "type": "dissolve", "duration": 0.6 } },
      "narration": {
        "text": "The hare loved to brag. He hopped in circles, laughing at how slow his friend was.",
        "granularity": "sentence", "marks": []
      },
      "cues": [
        { "type": "character", "t": 1.0, "target": "hare", "action": "hop" },
        { "type": "dialogue", "t": 3.0, "speaker": "hare", "text": "I am the fastest in the whole meadow! You could never beat me!", "emotion": "proud", "duckMusicDb": -6 },
        { "type": "character", "t": 6.0, "target": "hare", "action": "laugh" },
        { "type": "sfx", "t": 6.2, "sound": "giggle", "volume": 0.8 },
        { "type": "hold", "t": 7.0, "duration": 1.5 },
        { "type": "dialogue", "t": 8.5, "speaker": "tortoise", "text": "Then let us have a race. Slow and steady is my way.", "emotion": "determined", "duckMusicDb": -6 }
      ]
    },
    {
      "id": 3,
      "title": "On Your Marks",
      "minDuration": 9,
      "background": "forest",
      "mood": "cheerful",
      "timeOfDay": "morning",
      "weather": "clear",
      "lighting": "warm",
      "learningObjective": "The race begins; both try their best.",
      "cast": [
        { "id": "hare", "kind": "rabbit", "x": 0.3, "y": 0.7, "facing": "right", "emotion": "determined", "entrance": { "from": "left", "at": 0.5 } },
        { "id": "tortoise", "kind": "turtle", "x": 0.34, "y": 0.72, "facing": "right", "emotion": "determined" }
      ],
      "camera": {
        "from": { "zoom": 1.2, "offset": [-0.1, 0] },
        "to": { "zoom": 1.0, "offset": [0.1, 0] },
        "duration": 7, "ease": "easeOut", "startAt": 1.0
      },
      "particles": ["leaves"],
      "transition": { "in": { "type": "dissolve", "duration": 0.6 }, "out": { "type": "dissolve", "duration": 0.7 } },
      "narration": {
        "text": "A little bird counted them down. Three, two, one, go! The hare zoomed ahead in a cloud of dust.",
        "granularity": "sentence", "marks": []
      },
      "cues": [
        { "type": "sfx", "t": 2.5, "sound": "whoosh", "volume": 0.9 },
        { "type": "character", "t": 2.6, "target": "hare", "action": "run" },
        { "type": "music", "t": 3.0, "track": "playful", "volume": 0.7 },
        { "type": "character", "t": 4.0, "target": "tortoise", "action": "walk" },
        { "type": "interaction", "t": 0.0, "trigger": "tap", "target": "bird", "reaction": "flyAway", "sound": "chirp", "optional": true, "narrateOnMiss": false }
      ]
    },
    {
      "id": 4,
      "title": "A Cozy Nap",
      "minDuration": 12,
      "background": "forest",
      "mood": "sleepy",
      "timeOfDay": "afternoon",
      "weather": "clear",
      "lighting": "warm",
      "learningObjective": "Overconfidence: the hare rests.",
      "cast": [
        { "id": "hare", "kind": "rabbit", "x": 0.5, "y": 0.66, "facing": "right", "emotion": "sleepy" }
      ],
      "camera": {
        "from": { "target": "hare", "zoom": 1.0 },
        "to": { "target": "hare", "zoom": 1.3 },
        "duration": 8, "ease": "easeInOutSine", "startAt": 1.0
      },
      "audio": {
        "music": { "track": "calm", "volume": 0.4 },
        "ambience": { "bed": "birds_meadow", "volume": 0.3 }
      },
      "transition": { "in": { "type": "dissolve", "duration": 0.8 }, "out": { "type": "dissolve", "duration": 0.7 } },
      "narration": {
        "text": "The hare was so far ahead that he yawned. A little rest under this shady tree won't hurt, he thought. Soon he was fast asleep.",
        "granularity": "sentence", "marks": []
      },
      "cues": [
        { "type": "dialogue", "t": 3.0, "speaker": "hare", "text": "I am so far ahead... a little nap won't hurt.", "emotion": "sleepy", "duckMusicDb": -5 },
        { "type": "character", "t": 6.0, "target": "hare", "action": "sleep" },
        { "type": "sfx", "t": 6.5, "sound": "snore", "volume": 0.5 },
        { "type": "hold", "t": 7.0, "duration": 2.5 },
        { "type": "interaction", "t": 0.0, "trigger": "tap", "target": "cloud", "reaction": "drift", "sound": "soft_pop", "optional": true, "narrateOnMiss": false }
      ]
    },
    {
      "id": 5,
      "title": "Slow and Steady",
      "minDuration": 11,
      "background": "forest",
      "mood": "tender",
      "timeOfDay": "afternoon",
      "weather": "clear",
      "lighting": "warm",
      "learningObjective": "Persistence: the tortoise keeps going.",
      "cast": [
        { "id": "tortoise", "kind": "turtle", "x": 0.3, "y": 0.7, "facing": "right", "emotion": "determined" }
      ],
      "camera": {
        "from": { "target": "tortoise", "zoom": 1.15, "offset": [-0.15, 0] },
        "to": { "target": "tortoise", "zoom": 1.15, "offset": [0.15, 0] },
        "duration": 9, "ease": "linear", "startAt": 0.5
      },
      "audio": { "music": { "track": "calm", "volume": 0.5 } },
      "transition": { "in": { "type": "dissolve", "duration": 0.7 }, "out": { "type": "dissolve", "duration": 0.7 } },
      "narration": {
        "text": "Step by step, the tortoise walked past the sleeping hare. He never stopped. He never gave up. Slow, and steady.",
        "granularity": "sentence", "marks": []
      },
      "cues": [
        { "type": "character", "t": 1.0, "target": "tortoise", "action": "walk" },
        { "type": "music", "t": 6.0, "track": "playful", "volume": 0.6 },
        { "type": "dialogue", "t": 8.0, "speaker": "tortoise", "text": "Just keep going. The finish line is close now.", "emotion": "kind", "duckMusicDb": -5 }
      ]
    },
    {
      "id": 6,
      "title": "The Finish Line",
      "minDuration": 12,
      "background": "village",
      "mood": "triumphant",
      "timeOfDay": "afternoon",
      "weather": "clear",
      "lighting": "golden",
      "learningObjective": "The moral lands: steady effort wins; be humble and kind.",
      "cast": [
        { "id": "tortoise", "kind": "turtle", "x": 0.6, "y": 0.68, "facing": "right", "emotion": "happy" },
        { "id": "hare", "kind": "rabbit", "x": 0.25, "y": 0.66, "facing": "right", "emotion": "surprised", "entrance": { "from": "left", "at": 5.0 } }
      ],
      "camera": {
        "from": { "target": "tortoise", "zoom": 1.3 },
        "to": { "zoom": 1.0, "offset": [0, 0] },
        "duration": 6, "ease": "easeOutBack", "startAt": 3.0
      },
      "particles": ["stars"],
      "transition": { "in": { "type": "dissolve", "duration": 0.7 }, "out": { "type": "fade", "duration": 0.8 } },
      "narration": {
        "text": "The tortoise crossed the finish line first! The hare woke up and rushed over, out of breath. You won fair and square, he said with a smile. And from that day on, the hare never bragged again.",
        "granularity": "sentence", "marks": []
      },
      "cues": [
        { "type": "character", "t": 1.5, "target": "tortoise", "action": "celebrate" },
        { "type": "sfx", "t": 2.0, "sound": "cheer", "volume": 0.9 },
        { "type": "music", "t": 2.2, "track": "playful", "volume": 0.8 },
        { "type": "character", "t": 5.5, "target": "hare", "action": "run" },
        { "type": "dialogue", "t": 7.0, "speaker": "hare", "text": "You won fair and square. Slow and steady really does win the race!", "emotion": "kind", "duckMusicDb": -6 },
        { "type": "hold", "t": 9.5, "duration": 1.5 },
        { "type": "interaction", "t": 0.0, "trigger": "tap", "target": "stage", "reaction": "starBurst", "sound": "twinkle", "optional": true, "narrateOnMiss": false }
      ]
    }
  ]
}
''';
