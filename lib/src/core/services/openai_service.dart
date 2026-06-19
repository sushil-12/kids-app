import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/learn/data/learn_content.dart';
import '../../features/profile/data/child_profile.dart';

// ---------------------------------------------------------------------------
// Cost policy (read before changing):
//
//  • ABC lessons  — NEVER call the API. Full static dataset ships in the app.
//  • Poems        — API called only on explicit "New Poem" user action and
//                   only when no Hive cache entry exists for that refresh key.
//  • Daily story  — API called at most ONCE per day per age band. The result
//                   is cached permanently in Hive; same story all day.
//
// Future: swap this class for a BackendService that calls your own API which
// can serve datasets from your crawler without touching OpenAI at all.
//
// Build-time injection:
//   flutter run --dart-define=OPENAI_API_KEY=sk-...
// ---------------------------------------------------------------------------

const String _kApiKey = String.fromEnvironment('OPENAI_API_KEY');

// gpt-4o-mini: cheapest capable chat model (~$0.15 / 1M input tokens).
const String _kModel = 'gpt-4o-mini';
const String _kEndpoint = 'https://api.openai.com/v1/chat/completions';

class OpenAiService {
  const OpenAiService();

  bool get isConfigured => _kApiKey.isNotEmpty;

  Future<String> _complete(String system, String user) async {
    if (!isConfigured) throw const AiUnavailableException();

    final http.Response response = await http.post(
      Uri.parse(_kEndpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_kApiKey',
      },
      body: jsonEncode(<String, dynamic>{
        'model': _kModel,
        'max_tokens': 400,
        'temperature': 0.8,
        'messages': <Map<String, String>>[
          <String, String>{'role': 'system', 'content': system},
          <String, String>{'role': 'user', 'content': user},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw AiApiException(response.statusCode, response.body);
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> choices = json['choices'] as List<dynamic>;
    final Map<String, dynamic> msg =
        choices.first['message'] as Map<String, dynamic>;
    return msg['content'] as String;
  }

  Map<String, dynamic> _parseJson(String text) {
    final String clean =
        text.replaceAll(RegExp(r'```json?\s*|\s*```'), '').trim();
    return jsonDecode(clean) as Map<String, dynamic>;
  }

  /// Generates one age-appropriate story with a moral.
  /// Called at most once per day per age band — caller must cache the result.
  Future<DailyStory> generateDailyStory(AgeBand band, String date) async {
    final String ageDesc =
        band == AgeBand.junior ? '2–4 year olds' : '5–6 year olds';
    final String raw = await _complete(
      'You are a warm children\'s storyteller. Output ONLY valid JSON, no markdown.',
      'Write a short children\'s story for $ageDesc (date: $date). '
      'JSON keys: title, story (6-8 sentences), moral (1 sentence), emoji (1 emoji).',
    );
    final Map<String, dynamic> j = _parseJson(raw);
    return DailyStory(
      title: j['title'] as String,
      story: j['story'] as String,
      moral: j['moral'] as String,
      emoji: j['emoji'] as String,
      date: date,
    );
  }

  /// Generates a 4-line rhyming poem for a given topic.
  /// Only called when the user explicitly requests a new poem (FAB tap).
  Future<KidsPoem> generatePoem(String topic) async {
    final String raw = await _complete(
      'You are a children\'s poet for ages 5–6. Output ONLY valid JSON, no markdown.',
      'Write a 4-line rhyming poem about "$topic" for ages 5–6. '
      'JSON keys: title, poem (4 lines joined by \\n), emoji (1 emoji).',
    );
    final Map<String, dynamic> j = _parseJson(raw);
    return KidsPoem(
      title: j['title'] as String,
      poem: j['poem'] as String,
      topic: topic,
      emoji: j['emoji'] as String,
    );
  }
}

class AiUnavailableException implements Exception {
  const AiUnavailableException();
}

class AiApiException implements Exception {
  const AiApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

final openAiServiceProvider = Provider<OpenAiService>(
  (_) => const OpenAiService(),
);
