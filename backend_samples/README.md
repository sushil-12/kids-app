# Backend samples — cinematic stories

`cinematic_story_samples.json` is an array of story objects; each element is
**exactly** the wire shape `GET /v1/stories/cinematic/daily` must return (the
Flutter player parses it via `CinematicStory.fromJson`). When seeding, drop
`id`/`generatedAt` (the DB generates them) and add `published: true` — same as
`kids-app-backend/prisma/cinematic-seed.ts`.

## Illustration fields (new)

- `coverImage` (string | null) — cover art URL, shown on the end card.
- `scenes[].image` (string | null) — full-bleed illustration for the scene.

Both are **optional**: when null/missing or unreachable the app renders its
built-in vector stage, so stories always play. When present, the player shows
the illustration with a Ken Burns camera move and keeps the tap/drag hotspots
on top — so the artwork should depict the scene's props/characters roughly at
their `x`/`y` stage positions (0..1, y grows downward).

Backend TODO to make the sample URLs live:
1. Add `image`/`coverImage` to `src/services/cinematic.schema.ts`, the
   `CinematicStory` Prisma model, and `serializeCinematic` in
   `src/routes/v1/stories.ts`.
2. Host the PNGs at
   `https://api.brightmindkids.com/assets/stories/hare-and-tortoise/`
   (`cover.png`, `scene-1.png` … `scene-5.png`). Portrait, ~1080×1920,
   consistent character design across scenes (generate with an image model or
   commission; keep the same character reference per story).
