import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/learn/data/cinematic_story.dart';
import '../../features/learn/data/learn_content.dart';
import '../../features/profile/data/child_profile.dart';

// ---------------------------------------------------------------------------
// BrightMind Kids — Backend Content Service
//
// The app no longer calls OpenAI directly. All AI generation, caching, and
// dataset serving happens in the backend. The app is a pure consumer.
//
// Build-time injection (dart-define):
//   BACKEND_URL     — base URL of the backend (default: http://localhost:3000)
//   BACKEND_API_KEY — x-api-key header value
//
// Example:
//   flutter run \
//     --dart-define=BACKEND_URL=https://api.brightmindkids.com \
//     --dart-define=BACKEND_API_KEY=your-key-here
// ---------------------------------------------------------------------------

const String _kBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:3000',
);
const String _kApiKey = String.fromEnvironment('BACKEND_API_KEY');

class BackendService {
  const BackendService();

  bool get isConfigured => _kApiKey.isNotEmpty;

  Map<String, String> get _headers => <String, String>{
        'Content-Type': 'application/json',
        'x-api-key': _kApiKey,
      };

  Future<Map<String, dynamic>> _get(String path) async {
    final Uri uri = Uri.parse('$_kBaseUrl$path');
    try {
      final http.Response response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (kDebugMode) debugPrint('[backend] 200 GET $path');
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (kDebugMode) {
        debugPrint(
          '[backend] ${response.statusCode} GET $path → ${response.body}',
        );
      }
      throw BackendException(response.statusCode, response.body);
    } on BackendException {
      rethrow;
    } catch (e) {
      // Network/timeout/parse failure — surface it so callers fall back, but
      // make it visible during development why content went static.
      if (kDebugMode) debugPrint('[backend] FAILED GET $uri → $e');
      rethrow;
    }
  }

  Future<DailyStory> fetchDailyStory(AgeBand band) async {
    final String bandName = band == AgeBand.junior ? 'junior' : 'senior';
    final Map<String, dynamic> j =
        await _get('/v1/stories/daily?ageBand=$bandName');
    return DailyStory(
      title: j['title'] as String,
      story: j['story'] as String,
      moral: j['moral'] as String,
      emoji: j['emoji'] as String,
      date: j['generatedAt'] as String? ?? '',
    );
  }

  /// Today's cinematic scene-script story for the band + language. The
  /// backend returns 503 while it generates a fresh one — callers fall back
  /// to the bundled offline story.
  Future<CinematicStory> fetchCinematicStory(AgeBand band, String lang) async {
    final String bandName = band == AgeBand.junior ? 'junior' : 'senior';
    final Map<String, dynamic> j =
        await _get('/v1/stories/cinematic/daily?ageBand=$bandName&lang=$lang');
    return CinematicStory.fromJson(j);
  }

  Future<KidsPoem> fetchPoem(String topic) async {
    final String encoded = Uri.encodeComponent(topic);
    final Map<String, dynamic> j = await _get('/v1/poems?topic=$encoded');
    return KidsPoem(
      title: j['title'] as String,
      poem: j['poem'] as String,
      topic: j['topic'] as String? ?? topic,
      emoji: j['emoji'] as String,
    );
  }

  Future<AbcLesson> fetchAbcLesson(String letter) async {
    final Map<String, dynamic> j = await _get('/v1/abc/$letter');
    return AbcLesson(
      letter: j['letter'] as String,
      word: j['word'] as String,
      emoji: j['emoji'] as String,
      phonics: j['phonics'] as String,
      miniStory: j['miniStory'] as String,
    );
  }
}

class BackendException implements Exception {
  const BackendException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'BackendException($statusCode)';
}

final backendServiceProvider = Provider<BackendService>(
  (_) => const BackendService(),
);
