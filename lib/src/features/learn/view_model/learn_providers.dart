import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/backend_service.dart';
import '../../../features/profile/data/child_profile.dart';
import '../../../features/profile/view_model/profile_view_model.dart';
import '../data/content_cache.dart';
import '../data/learn_content.dart';

// ---------------------------------------------------------------------------
// Content resolution — 3 tiers, cheapest first:
//
//  Tier 1  Static dataset (ships in APK)     → instant, zero cost
//  Tier 2  Hive cache (device-local)          → instant, zero cost
//  Tier 3  Backend API                        → network call; backend decides
//          └─ Backend internally: DB → Redis → OpenAI (with daily cap)
//             The app doesn't know or care which backend tier was used.
//
// ABC lessons never leave Tier 1 — full A–Z is pre-written in the app.
// Stories  → Tier 3 at most once per day per age band, result cached in Hive.
// Poems    → Tier 1 on first load; Tier 3 only on explicit "New Poem" tap.
// ---------------------------------------------------------------------------

String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);

/// Increment to request a fresh story (new Hive key, triggers backend call).
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

  final String key = 'story_${band.name}_${_todayKey()}_r$refresh';

  // Tier 2: Hive cache — same story served instantly for the rest of the day.
  final String? cached = await cache.get(key);
  if (cached != null) {
    return DailyStory.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }

  // Tier 1: no backend key configured — serve bundled fallback.
  if (!backend.isConfigured) return LearnFallbacks.story;

  // Tier 3: backend call — result cached so this runs at most once per day.
  try {
    final DailyStory story = await backend.fetchDailyStory(band);
    await cache.set(key, jsonEncode(story.toJson()));
    return story;
  } catch (_) {
    return LearnFallbacks.story;
  }
});

// ── ABC Lessons ─────────────────────────────────────────────────────────────
// Tier 1 only — full A–Z ships with the app. No network call, ever.
// When the backend's own ABC dataset becomes richer, swap this to a backend
// call with a long Hive TTL (e.g. refresh weekly).

final abcLessonProvider =
    FutureProvider.autoDispose.family<AbcLesson, String>((
  AutoDisposeFutureProviderRef<AbcLesson> ref,
  String letter,
) async {
  return LearnFallbacks.abcLessons.firstWhere(
    (AbcLesson l) => l.letter == letter,
    orElse: () => LearnFallbacks.abcLessons.first,
  );
});

// ── Poems ────────────────────────────────────────────────────────────────────
// Tier 1 on first load (refresh == 0).
// Tier 2 on revisit (cached from a previous refresh).
// Tier 3 only when the user explicitly taps "New Poem" (refresh > 0).

final poemProvider = FutureProvider.autoDispose.family<KidsPoem, String>((
  AutoDisposeFutureProviderRef<KidsPoem> ref,
  String topic,
) async {
  final int refresh = ref.watch(poemRefreshProvider);
  final BackendService backend = ref.watch(backendServiceProvider);
  final ContentCache cache = ref.watch(contentCacheProvider);

  // Tier 1: bundled poem on first load.
  if (refresh == 0) {
    return LearnFallbacks.poems.firstWhere(
      (KidsPoem p) => p.topic == topic,
      orElse: () => LearnFallbacks.poems.first,
    );
  }

  // Tier 2: Hive cache for a previously fetched poem at this refresh index.
  final String slug = topic.toLowerCase().replaceAll(' ', '_');
  final String key = 'poem_${slug}_r$refresh';
  final String? cached = await cache.get(key);
  if (cached != null) {
    return KidsPoem.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }

  // Tier 1 fallback when backend not configured.
  if (!backend.isConfigured) {
    return LearnFallbacks.poems.firstWhere(
      (KidsPoem p) => p.topic == topic,
      orElse: () => LearnFallbacks.poems.first,
    );
  }

  // Tier 3: user explicitly asked for something new.
  try {
    final KidsPoem poem = await backend.fetchPoem(topic);
    await cache.set(key, jsonEncode(poem.toJson()));
    return poem;
  } catch (_) {
    return LearnFallbacks.poems.firstWhere(
      (KidsPoem p) => p.topic == topic,
      orElse: () => LearnFallbacks.poems.first,
    );
  }
});
