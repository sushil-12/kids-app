import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;

import 'coloring_template.dart';
import 'coloring_templates.dart';

/// Base URL of the BrightMind content backend (kids-app-backend).
/// Override per build with: `--dart-define=BACKEND_URL=https://api.example.com`.
/// Uses the same defines as [BackendService] so one set of flags wires the
/// whole app (default localhost works on iOS sim; use 10.0.2.2 on Android).
const String _kBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:3000',
);

/// Shared API key sent as `x-api-key` (matches the backend's authenticate hook).
const String _kApiKey = String.fromEnvironment('BACKEND_API_KEY');

const String _kCacheBox = 'coloring_cache';
const String _kCacheKey = 'pages_json';

/// Fetches backend coloring pages and caches the raw JSON in Hive so the
/// gallery still fills up on a cold, offline start.
class ColoringRepository {
  Future<List<ColoringTemplate>> fetchRemote() async {
    final Uri uri = Uri.parse('$_kBaseUrl/v1/coloring');
    final http.Response res = await http.get(
      uri,
      headers: <String, String>{if (_kApiKey.isNotEmpty) 'x-api-key': _kApiKey},
    );
    if (res.statusCode != 200) {
      throw Exception('coloring fetch failed: HTTP ${res.statusCode}');
    }
    await _writeCache(res.body);
    return _parse(res.body);
  }

  Future<List<ColoringTemplate>> cached() async {
    final Box<String> box = await Hive.openBox<String>(_kCacheBox);
    final String? body = box.get(_kCacheKey);
    return body == null ? <ColoringTemplate>[] : _parse(body);
  }

  Future<void> _writeCache(String body) async {
    final Box<String> box = await Hive.openBox<String>(_kCacheBox);
    await box.put(_kCacheKey, body);
  }

  List<ColoringTemplate> _parse(String body) {
    final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
    final List<dynamic> pages = json['pages'] as List<dynamic>? ?? <dynamic>[];
    final List<ColoringTemplate> out = <ColoringTemplate>[];
    for (final dynamic p in pages) {
      try {
        out.add(ColoringTemplate.fromJson(p as Map<String, dynamic>));
      } catch (e) {
        // One malformed page must never break the whole gallery.
        debugPrint('Skipping bad coloring page: $e');
      }
    }
    return out;
  }
}

/// Loads remote pages cache-first then over the network, merging both into the
/// shared [kColoringTemplates] catalog. The gallery watches this to rebuild
/// once fresh pages arrive; bundled pages render immediately regardless.
final FutureProvider<List<ColoringTemplate>> coloringCatalogProvider =
    FutureProvider<List<ColoringTemplate>>((Ref ref) async {
  final ColoringRepository repo = ColoringRepository();

  final List<ColoringTemplate> cached = await repo.cached();
  if (cached.isNotEmpty) mergeRemoteTemplates(cached);

  try {
    mergeRemoteTemplates(await repo.fetchRemote());
  } catch (e) {
    debugPrint('Coloring remote fetch failed (using cache/bundled): $e');
  }

  return kColoringTemplates;
});
