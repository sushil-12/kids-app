import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/learn/data/learn_content.dart';
import '../../features/profile/data/child_profile.dart';

// API key is injected at build time:
//   flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
// In production, route through your own backend proxy instead of calling
// the Anthropic API directly from the client.
const String _kApiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
const String _kModel = 'claude-haiku-4-5-20251001';
const String _kEndpoint = 'https://api.anthropic.com/v1/messages';

class ClaudeService {
  const ClaudeService();

  bool get isConfigured => _kApiKey.isNotEmpty;

  Future<String> _complete(String system, String user) async {
    if (!isConfigured) throw const ClaudeUnavailableException();

    final http.Response response = await http.post(
      Uri.parse(_kEndpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'x-api-key': _kApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(<String, dynamic>{
        'model': _kModel,
        'max_tokens': 512,
        'system': system,
        'messages': <Map<String, String>>[
          <String, String>{'role': 'user', 'content': user},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw ClaudeApiException(response.statusCode, response.body);
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> content = json['content'] as List<dynamic>;
    return content.first['text'] as String;
  }

  Map<String, dynamic> _parseJson(String text) {
    final String clean =
        text.replaceAll(RegExp(r'```json?\s*|\s*```'), '').trim();
    return jsonDecode(clean) as Map<String, dynamic>;
  }

  Future<DailyStory> generateDailyStory(AgeBand band, String date) async {
    final String ageDesc =
        band == AgeBand.junior ? '2–4 year olds' : '5–6 year olds';
    final String text = await _complete(
      'You are a warm children\'s storyteller. Respond with valid JSON only, no markdown.',
      'Generate a short children\'s story for $ageDesc. Date: $date. '
      'Return JSON: {"title":"...","story":"6-8 engaging sentences","moral":"one sentence lesson","emoji":"single emoji"}',
    );
    final Map<String, dynamic> j = _parseJson(text);
    return DailyStory(
      title: j['title'] as String,
      story: j['story'] as String,
      moral: j['moral'] as String,
      emoji: j['emoji'] as String,
      date: date,
    );
  }

  Future<AbcLesson> generateAbcLesson(String letter) async {
    final String text = await _complete(
      'You are a children\'s phonics teacher for ages 2–4. Respond with valid JSON only, no markdown.',
      'Generate an ABC lesson for the letter "$letter". '
      'Return JSON: {"letter":"$letter","word":"...","emoji":"single emoji","phonics":"short phonics tip e.g. A says /æ/ like in apple","miniStory":"2-3 short fun sentences"}',
    );
    final Map<String, dynamic> j = _parseJson(text);
    return AbcLesson(
      letter: j['letter'] as String,
      word: j['word'] as String,
      emoji: j['emoji'] as String,
      phonics: j['phonics'] as String,
      miniStory: j['miniStory'] as String,
    );
  }

  Future<KidsPoem> generatePoem(String topic) async {
    final String text = await _complete(
      'You are a children\'s poet for ages 5–6. Respond with valid JSON only, no markdown.',
      'Write a 4-line rhyming poem about "$topic" for children aged 5–6. '
      'Return JSON: {"title":"...","poem":"line1\\nline2\\nline3\\nline4","emoji":"single emoji"}',
    );
    final Map<String, dynamic> j = _parseJson(text);
    return KidsPoem(
      title: j['title'] as String,
      poem: j['poem'] as String,
      topic: topic,
      emoji: j['emoji'] as String,
    );
  }
}

class ClaudeUnavailableException implements Exception {
  const ClaudeUnavailableException();
}

class ClaudeApiException implements Exception {
  const ClaudeApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

final claudeServiceProvider = Provider<ClaudeService>(
  (_) => const ClaudeService(),
);
