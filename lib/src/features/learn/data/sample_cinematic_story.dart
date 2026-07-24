import 'dart:convert';

import 'cinematic_story.dart';

// ---------------------------------------------------------------------------
// TEMP — sample backend response for the cinematic story player.
//
// Each string below is byte-for-byte the wire shape that
// `GET /v1/stories/cinematic/daily?ageBand=junior&lang=…` returns (see
// backend_samples/cinematic_story_samples.json for the copy to send to the
// backend team). While the backend copy is being set up,
// `cinematicStoryProvider` serves the player from this JSON instead of
// calling the backend; it goes through the same `jsonDecode` +
// `CinematicStory.fromJson` path a real response would, so swapping the
// backend back in changes nothing else.
//
// Delete this file and restore the commented block in
// `view_model/learn_providers.dart` once the backend serves this story.
// ---------------------------------------------------------------------------

/// The sample story for a language code ('hi' → Hindi, anything else → en),
/// parsed from the raw wire JSON exactly like a backend response.
CinematicStory sampleCinematicStoryFor(String lang) => CinematicStory.fromJson(
      jsonDecode(lang == 'hi' ? _wireJsonHi : _wireJsonEn)
          as Map<String, dynamic>,
    );

const String _wireJsonEn = '''
{
  "id": "sample-hare-tortoise-en",
  "slug": "hare-and-tortoise-en",
  "title": "The Hare and the Tortoise",
  "lang": "en",
  "ageBand": "junior",
  "category": "Moral Stories",
  "coverEmoji": "🐢",
  "coverImage": "https://api.brightmindkids.com/assets/stories/hare-and-tortoise/cover.png",
  "music": "playful",
  "moral": "Slow and steady wins the race.",
  "reward": { "stars": 10, "coins": 5, "badgeStickerId": "star" },
  "date": null,
  "source": "manual",
  "generatedAt": "2026-07-20T00:00:00.000Z",
  "scenes": [
    {
      "id": 1,
      "image": "https://i.ibb.co/fG2MzcMg/Gemini-Generated-Image-6w603j6w603j6w60.png",
      "title": "The Big Boast",
      "minDuration": 8,
      "background": "forest",
      "narration": "In a green forest lived a speedy rabbit and a slow, smiling turtle. 'I am the fastest in the forest!' said the rabbit. 'Let us race!'",
      "camera": { "effect": "zoom_in" },
      "props": [
        { "id": "tree", "kind": "tree", "x": 0.15, "y": 0.6, "scale": 1.1 },
        { "id": "bush", "kind": "bush", "x": 0.85, "y": 0.72, "scale": 0.9 }
      ],
      "characters": [
        { "id": "rabbit", "kind": "rabbit", "x": 0.35, "y": 0.55, "scale": 1, "animation": "hop" },
        { "id": "turtle", "kind": "turtle", "x": 0.62, "y": 0.62, "scale": 1, "animation": "idle" }
      ],
      "particles": ["leaves", "birds"],
      "interaction": {
        "type": "tap",
        "target": "rabbit",
        "hint": "Tap the speedy rabbit!",
        "sound": "pop"
      }
    },
    {
      "id": 2,
      "image": "https://api.brightmindkids.com/assets/stories/hare-and-tortoise/scene-2.png",
      "title": "The Race Begins",
      "minDuration": 8,
      "background": "forest",
      "narration": "Ready, set, go! The rabbit hopped away so fast. The turtle walked slowly, step by step, and did not stop.",
      "camera": { "effect": "pan_right" },
      "props": [
        { "id": "tree", "kind": "tree", "x": 0.8, "y": 0.58, "scale": 1.2 },
        { "id": "flower", "kind": "flower", "x": 0.2, "y": 0.8, "scale": 0.8 }
      ],
      "characters": [
        { "id": "rabbit", "kind": "rabbit", "x": 0.7, "y": 0.55, "scale": 1, "animation": "hop" },
        { "id": "turtle", "kind": "turtle", "x": 0.25, "y": 0.62, "scale": 1, "animation": "walk" }
      ],
      "particles": ["wind"],
      "interaction": null
    },
    {
      "id": 3,
      "image": "https://api.brightmindkids.com/assets/stories/hare-and-tortoise/scene-3.png",
      "title": "Nap Time",
      "minDuration": 8,
      "background": "forest",
      "narration": "'The turtle is far behind,' laughed the rabbit. 'I will take a little nap.' And he fell fast asleep under a tree.",
      "camera": { "effect": "zoom_in" },
      "props": [
        { "id": "tree", "kind": "tree", "x": 0.5, "y": 0.5, "scale": 1.3 },
        { "id": "rock", "kind": "rock", "x": 0.8, "y": 0.82, "scale": 0.8 }
      ],
      "characters": [
        { "id": "rabbit", "kind": "rabbit", "x": 0.45, "y": 0.68, "scale": 1, "animation": "idle" },
        { "id": "turtle", "kind": "turtle", "x": 0.12, "y": 0.72, "scale": 0.9, "animation": "walk" }
      ],
      "particles": ["leaves"],
      "interaction": null
    },
    {
      "id": 4,
      "image": "https://api.brightmindkids.com/assets/stories/hare-and-tortoise/scene-4.png",
      "title": "Step by Step",
      "minDuration": 9,
      "background": "forest",
      "narration": "While the rabbit slept, the turtle kept walking. Can you help the turtle reach the finish flower?",
      "camera": { "effect": "none" },
      "props": [
        { "id": "flower", "kind": "flower", "x": 0.82, "y": 0.7, "scale": 1.1 },
        { "id": "bush", "kind": "bush", "x": 0.5, "y": 0.8, "scale": 0.9 }
      ],
      "characters": [
        { "id": "turtle", "kind": "turtle", "x": 0.18, "y": 0.65, "scale": 1.1, "animation": "walk" }
      ],
      "particles": ["birds"],
      "interaction": {
        "type": "drag",
        "target": "turtle",
        "dropZone": "flower",
        "hint": "Take the turtle to the finish flower!",
        "sound": "plop"
      }
    },
    {
      "id": 5,
      "image": "https://api.brightmindkids.com/assets/stories/hare-and-tortoise/scene-5.png",
      "title": "Slow and Steady",
      "minDuration": 8,
      "background": "sky",
      "narration": "The rabbit woke up and ran, but the turtle had already won! Slow and steady wins the race.",
      "camera": { "effect": "zoom_out" },
      "props": [
        { "id": "sun", "kind": "sun", "x": 0.8, "y": 0.15, "scale": 1 },
        { "id": "cloud", "kind": "cloud", "x": 0.22, "y": 0.2, "scale": 1 }
      ],
      "characters": [
        { "id": "turtle", "kind": "turtle", "x": 0.45, "y": 0.55, "scale": 1.2, "animation": "bounce" },
        { "id": "rabbit", "kind": "rabbit", "x": 0.75, "y": 0.6, "scale": 0.9, "animation": "hop" }
      ],
      "particles": ["birds", "wind"],
      "interaction": null
    }
  ]
}
''';

const String _wireJsonHi = '''
{
  "id": "sample-hare-tortoise-hi",
  "slug": "hare-and-tortoise-hi",
  "title": "खरगोश और कछुआ",
  "lang": "hi",
  "ageBand": "junior",
  "category": "Moral Stories",
  "coverEmoji": "🐢",
  "coverImage": "https://api.brightmindkids.com/assets/stories/hare-and-tortoise/cover.png",
  "music": "playful",
  "moral": "धीरे और लगातार चलने वाला ही जीतता है।",
  "reward": { "stars": 10, "coins": 5, "badgeStickerId": "star" },
  "date": null,
  "source": "manual",
  "generatedAt": "2026-07-20T00:00:00.000Z",
  "scenes": [
    {
      "id": 1,
      "image": "https://api.brightmindkids.com/assets/stories/hare-and-tortoise/scene-1.png",
      "title": "घमंडी खरगोश",
      "minDuration": 8,
      "background": "forest",
      "narration": "हरे-भरे जंगल में एक तेज़ खरगोश और एक धीमा कछुआ रहते थे। खरगोश बोला, 'मैं सबसे तेज़ हूँ! चलो दौड़ लगाएँ!'",
      "camera": { "effect": "zoom_in" },
      "props": [
        { "id": "tree", "kind": "tree", "x": 0.15, "y": 0.6, "scale": 1.1 },
        { "id": "bush", "kind": "bush", "x": 0.85, "y": 0.72, "scale": 0.9 }
      ],
      "characters": [
        { "id": "rabbit", "kind": "rabbit", "x": 0.35, "y": 0.55, "scale": 1, "animation": "hop" },
        { "id": "turtle", "kind": "turtle", "x": 0.62, "y": 0.62, "scale": 1, "animation": "idle" }
      ],
      "particles": ["leaves", "birds"],
      "interaction": {
        "type": "tap",
        "target": "rabbit",
        "hint": "तेज़ खरगोश को छुओ!",
        "sound": "pop"
      }
    },
    {
      "id": 2,
      "image": "https://api.brightmindkids.com/assets/stories/hare-and-tortoise/scene-2.png",
      "title": "दौड़ शुरू",
      "minDuration": 8,
      "background": "forest",
      "narration": "एक, दो, तीन — दौड़ शुरू! खरगोश तेज़ी से कूदता चला गया। कछुआ धीरे-धीरे, कदम-कदम चलता रहा।",
      "camera": { "effect": "pan_right" },
      "props": [
        { "id": "tree", "kind": "tree", "x": 0.8, "y": 0.58, "scale": 1.2 },
        { "id": "flower", "kind": "flower", "x": 0.2, "y": 0.8, "scale": 0.8 }
      ],
      "characters": [
        { "id": "rabbit", "kind": "rabbit", "x": 0.7, "y": 0.55, "scale": 1, "animation": "hop" },
        { "id": "turtle", "kind": "turtle", "x": 0.25, "y": 0.62, "scale": 1, "animation": "walk" }
      ],
      "particles": ["wind"],
      "interaction": null
    },
    {
      "id": 3,
      "image": "https://api.brightmindkids.com/assets/stories/hare-and-tortoise/scene-3.png",
      "title": "खरगोश की झपकी",
      "minDuration": 8,
      "background": "forest",
      "narration": "'कछुआ तो बहुत पीछे है,' खरगोश हँसा। 'थोड़ी झपकी ले लूँ।' और वह पेड़ के नीचे सो गया।",
      "camera": { "effect": "zoom_in" },
      "props": [
        { "id": "tree", "kind": "tree", "x": 0.5, "y": 0.5, "scale": 1.3 },
        { "id": "rock", "kind": "rock", "x": 0.8, "y": 0.82, "scale": 0.8 }
      ],
      "characters": [
        { "id": "rabbit", "kind": "rabbit", "x": 0.45, "y": 0.68, "scale": 1, "animation": "idle" },
        { "id": "turtle", "kind": "turtle", "x": 0.12, "y": 0.72, "scale": 0.9, "animation": "walk" }
      ],
      "particles": ["leaves"],
      "interaction": null
    },
    {
      "id": 4,
      "image": "https://api.brightmindkids.com/assets/stories/hare-and-tortoise/scene-4.png",
      "title": "कदम-कदम आगे",
      "minDuration": 9,
      "background": "forest",
      "narration": "खरगोश सोता रहा, पर कछुआ चलता रहा। क्या तुम कछुए को फूल तक पहुँचा सकते हो?",
      "camera": { "effect": "none" },
      "props": [
        { "id": "flower", "kind": "flower", "x": 0.82, "y": 0.7, "scale": 1.1 },
        { "id": "bush", "kind": "bush", "x": 0.5, "y": 0.8, "scale": 0.9 }
      ],
      "characters": [
        { "id": "turtle", "kind": "turtle", "x": 0.18, "y": 0.65, "scale": 1.1, "animation": "walk" }
      ],
      "particles": ["birds"],
      "interaction": {
        "type": "drag",
        "target": "turtle",
        "dropZone": "flower",
        "hint": "कछुए को फूल तक ले जाओ!",
        "sound": "plop"
      }
    },
    {
      "id": 5,
      "image": "https://api.brightmindkids.com/assets/stories/hare-and-tortoise/scene-5.png",
      "title": "धीरे और लगातार",
      "minDuration": 8,
      "background": "sky",
      "narration": "खरगोश जागकर दौड़ा, पर कछुआ जीत चुका था! धीरे और लगातार चलने वाला ही जीतता है।",
      "camera": { "effect": "zoom_out" },
      "props": [
        { "id": "sun", "kind": "sun", "x": 0.8, "y": 0.15, "scale": 1 },
        { "id": "cloud", "kind": "cloud", "x": 0.22, "y": 0.2, "scale": 1 }
      ],
      "characters": [
        { "id": "turtle", "kind": "turtle", "x": 0.45, "y": 0.55, "scale": 1.2, "animation": "bounce" },
        { "id": "rabbit", "kind": "rabbit", "x": 0.75, "y": 0.6, "scale": 0.9, "animation": "hop" }
      ],
      "particles": ["birds", "wind"],
      "interaction": null
    }
  ]
}
''';
