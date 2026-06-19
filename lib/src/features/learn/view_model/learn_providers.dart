import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/openai_service.dart';
import '../../../features/profile/data/child_profile.dart';
import '../../../features/profile/view_model/profile_view_model.dart';
import '../data/content_cache.dart';
import '../data/learn_content.dart';

// ---------------------------------------------------------------------------
// Cost model — three tiers, cheapest wins:
//
//  Tier 1 — Static data   (zero cost, ships in APK)
//  Tier 2 — Hive cache    (zero cost, device-local)
//  Tier 3 — OpenAI API    (paid; only as a last resort, results always cached)
//
// ABC lessons are permanently in Tier 1 — they never reach Tier 3.
// Stories  → Tier 3 at most once per day per age band.
// Poems    → Tier 3 only on explicit "New Poem" action (user intent signal).
//
// Future work: insert a Tier 2.5 — your own backend serving crawled datasets.
// Replace openAiServiceProvider override in main.dart with backendServiceProvider
// and zero calls will reach OpenAI for common content.
// ---------------------------------------------------------------------------

String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);

/// Increment to request a fresh story (skips today's Hive cache entry).
final storyRefreshProvider = StateProvider<int>((_) => 0);

/// Increment to request a fresh poem for the current topic.
final poemRefreshProvider = StateProvider<int>((_) => 0);

// ── Daily Story ─────────────────────────────────────────────────────────────

final dailyStoryProvider = FutureProvider.autoDispose<DailyStory>((
  AutoDisposeFutureProviderRef<DailyStory> ref,
) async {
  final int refresh = ref.watch(storyRefreshProvider);
  final OpenAiService ai = ref.watch(openAiServiceProvider);
  final ContentCache cache = ref.watch(contentCacheProvider);
  final ChildProfile? profile = ref.watch(profileProvider);
  final AgeBand band = profile?.ageBand ?? AgeBand.junior;

  // Cache key includes date so the story refreshes naturally each day.
  // Including the refresh counter lets the user request a second story
  // for the day while still keeping the original cached.
  final String key = 'story_${band.name}_${_todayKey()}_r$refresh';

  final String? cached = await cache.get(key);
  if (cached != null) {
    return DailyStory.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }

  // Tier 1: static fallback when no key or on first launch.
  if (!ai.isConfigured) return LearnFallbacks.story;

  // Tier 3: call OpenAI, then permanently cache.
  try {
    final DailyStory story = await ai.generateDailyStory(band, _todayKey());
    await cache.set(key, jsonEncode(story.toJson()));
    return story;
  } catch (_) {
    return LearnFallbacks.story;
  }
});

// ── ABC Lessons ─────────────────────────────────────────────────────────────
// Tier 1 only. The complete A–Z static dataset ships with the app.
// We intentionally never call the AI for ABC — the dataset is authoritative.

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

// ── Poems ───────────────────────────────────────────────────────────────────
// Tier 1 for the initial 5-poem set. Tier 2 (cache) on revisit.
// Tier 3 only on explicit "New Poem" FAB tap (refresh > 0) and cache miss.

final poemProvider = FutureProvider.autoDispose.family<KidsPoem, String>((
  AutoDisposeFutureProviderRef<KidsPoem> ref,
  String topic,
) async {
  final int refresh = ref.watch(poemRefreshProvider);
  final OpenAiService ai = ref.watch(openAiServiceProvider);
  final ContentCache cache = ref.watch(contentCacheProvider);

  // Tier 1: serve bundled poem on first load (refresh == 0).
  if (refresh == 0) {
    return LearnFallbacks.poems.firstWhere(
      (KidsPoem p) => p.topic == topic,
      orElse: () => LearnFallbacks.poems.first,
    );
  }

  // Tier 2: Hive cache for any previously generated poem.
  final String slug = topic.toLowerCase().replaceAll(' ', '_');
  final String key = 'poem_${slug}_r$refresh';
  final String? cached = await cache.get(key);
  if (cached != null) {
    return KidsPoem.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }

  // Tier 3: user explicitly asked for something new — call OpenAI once.
  if (!ai.isConfigured) {
    return LearnFallbacks.poems.firstWhere(
      (KidsPoem p) => p.topic == topic,
      orElse: () => LearnFallbacks.poems.first,
    );
  }

  try {
    final KidsPoem poem = await ai.generatePoem(topic);
    await cache.set(key, jsonEncode(poem.toJson()));
    return poem;
  } catch (_) {
    return LearnFallbacks.poems.firstWhere(
      (KidsPoem p) => p.topic == topic,
      orElse: () => LearnFallbacks.poems.first,
    );
  }
});
