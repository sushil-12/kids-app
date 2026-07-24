import 'dart:convert';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/locale_controller.dart';
import '../../../core/services/backend_service.dart';
import '../../../features/profile/data/child_profile.dart';
import '../../../features/profile/view_model/profile_view_model.dart';
// TEMP: fallback unused while the cinematic story is served from sample JSON.
// import '../data/cinematic_fallbacks.dart';
import '../data/cinematic_story.dart';
import '../data/cinematic_story_v2.dart';
import '../data/sample_cinematic_story.dart';
import '../data/sample_cinematic_story_v2.dart';
import '../data/content_cache.dart';
import '../data/learn_content.dart';

// ---------------------------------------------------------------------------
// Content resolution — backend-first, with offline fallback:
//
//  Tier 1  Hive cache (device-local)   → instant, zero cost, survives offline
//  Tier 2  Backend API                 → live source; the backend internally
//          └─ DB → Redis → OpenAI (with a daily cap). The app neither knows
//             nor cares which backend tier answered.
//  Tier 3  Static dataset (LearnFallbacks, bundled in the APK) → the safety
//          net when the backend is unreachable or unconfigured.
//
// The app never calls OpenAI directly anymore — that moved server-side.
// Each item is fetched from the backend once, then served from Hive.
// ---------------------------------------------------------------------------

String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);

/// Increment to request a fresh story (new Hive key, triggers a backend call).
final storyRefreshProvider = StateProvider<int>((_) => 0);

/// Increment to request a fresh poem for the current topic.
final poemRefreshProvider = StateProvider<int>((_) => 0);

// ── Daily Story ─────────────────────────────────────────────────────────────

final dailyStoryProvider = FutureProvider.autoDispose<DailyStory>((
  AutoDisposeFutureProviderRef<DailyStory> ref,
) async {
  final int refresh = ref.watch(storyRefreshProvider);
  final BackendService backend = ref.watch(backendServiceProvider);
  final ContentCache cache = ref.watch(contentCacheProvider);
  final ChildProfile? profile = ref.watch(profileProvider);
  final AgeBand band = profile?.ageBand ?? AgeBand.junior;

  // Key includes the date so the story refreshes naturally each day; the
  // refresh counter lets the child ask for another story while keeping today's.
  final String key = 'story_${band.name}_${_todayKey()}_r$refresh';

  final String? cached = await cache.get(key);
  if (cached != null) {
    return DailyStory.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }

  if (!backend.isConfigured) return LearnFallbacks.story;

  try {
    final DailyStory story = await backend.fetchDailyStory(band);
    await cache.set(key, jsonEncode(story.toJson()));
    return story;
  } catch (_) {
    return LearnFallbacks.story;
  }
});

// ── Cinematic Story ─────────────────────────────────────────────────────────
// The scene-based interactive story the player screen renders. Same 3-tier
// flow as the flat daily story; keyed additionally by language so switching
// the app to Hindi fetches the Hindi script.

final cinematicStoryProvider = FutureProvider.autoDispose<CinematicStory>((
  Ref ref,
) async {
  final Locale locale =
      ref.watch(localeControllerProvider) ?? PlatformDispatcher.instance.locale;
  final String lang = locale.languageCode == 'hi' ? 'hi' : 'en';

  // TEMP: serve the player from the bundled sample wire JSON (the exact shape
  // the backend returns — see data/sample_cinematic_story.dart) while the
  // backend copy of this story is being set up. To go backend-first again,
  // delete the next line + the sample file and un-comment the block below.
  return sampleCinematicStoryFor(lang);

  // final int refresh = ref.watch(storyRefreshProvider);
  // final BackendService backend = ref.watch(backendServiceProvider);
  // final ContentCache cache = ref.watch(contentCacheProvider);
  // final ChildProfile? profile = ref.watch(profileProvider);
  // final AgeBand band = profile?.ageBand ?? AgeBand.junior;
  //
  // final String key = 'cine_${band.name}_${lang}_${_todayKey()}_r$refresh';
  //
  // final String? cached = await cache.get(key);
  // if (cached != null) {
  //   return CinematicStory.fromJson(
  //     jsonDecode(cached) as Map<String, dynamic>,
  //   );
  // }
  //
  // if (!backend.isConfigured) return CinematicFallbacks.storyFor(lang);
  //
  // try {
  //   final CinematicStory story = await backend.fetchCinematicStory(band, lang);
  //   await cache.set(key, jsonEncode(story.toJson()));
  //   return story;
  // } catch (_) {
  //   return CinematicFallbacks.storyFor(lang);
  // }
});

// ── Cinematic Story v2 (director track) ──────────────────────────────────────
// The timeline-based player (SceneClock + CueScheduler + CameraRig). Served
// from the bundled v2 sample wire JSON for now — the exact shape the backend
// will return (see data/sample_cinematic_story_v2.dart +
// backend_samples/cinematic_story_v2_hare_and_tortoise.json). Swaps to a real
// backend fetch the same way the v1 provider does.

final cinematicStoryV2Provider = FutureProvider.autoDispose<CinematicStoryV2>((
  Ref ref,
) async {
  final Locale locale =
      ref.watch(localeControllerProvider) ?? PlatformDispatcher.instance.locale;
  final String lang = locale.languageCode == 'hi' ? 'hi' : 'en';
  return sampleCinematicStoryV2For(lang);
});

// ── ABC Lessons ─────────────────────────────────────────────────────────────
// Backend-served so curated/crawled lessons can evolve, cached per letter,
// with the bundled A–Z dataset as the offline fallback.

final abcLessonProvider = FutureProvider.autoDispose.family<AbcLesson, String>((
  AutoDisposeFutureProviderRef<AbcLesson> ref,
  String letter,
) async {
  final BackendService backend = ref.watch(backendServiceProvider);
  final ContentCache cache = ref.watch(contentCacheProvider);

  AbcLesson staticFallback() => LearnFallbacks.abcLessons.firstWhere(
        (AbcLesson l) => l.letter == letter,
        orElse: () => LearnFallbacks.abcLessons.first,
      );

  if (!backend.isConfigured) return staticFallback();

  final String key = 'abc_$letter';
  final String? cached = await cache.get(key);
  if (cached != null) {
    return AbcLesson.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }

  try {
    final AbcLesson lesson = await backend.fetchAbcLesson(letter);
    await cache.set(key, jsonEncode(lesson.toJson()));
    return lesson;
  } catch (_) {
    return staticFallback();
  }
});

// ── Poems ────────────────────────────────────────────────────────────────────
// Backend-served by topic, cached per (topic, refresh). The "New Poem" FAB
// bumps [poemRefreshProvider] to fetch fresh content from the backend.

final poemProvider = FutureProvider.autoDispose.family<KidsPoem, String>((
  AutoDisposeFutureProviderRef<KidsPoem> ref,
  String topic,
) async {
  final int refresh = ref.watch(poemRefreshProvider);
  final BackendService backend = ref.watch(backendServiceProvider);
  final ContentCache cache = ref.watch(contentCacheProvider);

  KidsPoem staticFallback() => LearnFallbacks.poems.firstWhere(
        (KidsPoem p) => p.topic == topic,
        orElse: () => LearnFallbacks.poems.first,
      );

  if (!backend.isConfigured) return staticFallback();

  final String slug = topic.toLowerCase().replaceAll(' ', '_');
  final String key = 'poem_${slug}_r$refresh';
  final String? cached = await cache.get(key);
  if (cached != null) {
    return KidsPoem.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }

  try {
    final KidsPoem poem = await backend.fetchPoem(topic);
    await cache.set(key, jsonEncode(poem.toJson()));
    return poem;
  } catch (_) {
    return staticFallback();
  }
});
