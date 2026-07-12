import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/backend_service.dart' show BackendException;
import 'admin_models.dart';

// ---------------------------------------------------------------------------
// BrightMind Kids — Admin Service
//
// Talks to the admin-only backend endpoints using the `x-admin-key` header.
// The key is supplied per call (held by the view-model, sourced from on-device
// storage) — never baked into the binary. Mirrors `BackendService`, but for the
// operator-facing endpoints behind the parent gate.
//
// Base URL reuses the same build-time `BACKEND_URL` define as BackendService.
// ---------------------------------------------------------------------------

const String _kBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:3000',
);

class AdminService {
  const AdminService();

  Map<String, String> _headers(String adminKey) => <String, String>{
        'Content-Type': 'application/json',
        'x-admin-key': adminKey,
      };

  Future<http.Response> _send(
    String method,
    String path,
    String adminKey, {
    Map<String, dynamic>? body,
  }) async {
    final Uri uri = Uri.parse('$_kBaseUrl$path');
    final http.Request req = http.Request(method, uri)
      ..headers.addAll(_headers(adminKey));
    if (body != null) req.body = jsonEncode(body);
    final http.StreamedResponse streamed =
        await req.send().timeout(const Duration(seconds: 12));
    return http.Response.fromStream(streamed);
  }

  Future<BackendStats> fetchStats(String adminKey) async {
    final http.Response r = await _send('GET', '/v1/stats', adminKey);
    if (r.statusCode != 200) {
      if (kDebugMode) debugPrint('[admin] ${r.statusCode} GET /v1/stats');
      throw BackendException(r.statusCode, r.body);
    }
    return BackendStats.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<List<CrawlSourceInfo>> fetchCrawlSources(String adminKey) async {
    final http.Response r = await _send('GET', '/v1/crawl/sources', adminKey);
    if (r.statusCode != 200) {
      throw BackendException(r.statusCode, r.body);
    }
    final List<dynamic> list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map(
          (dynamic e) => CrawlSourceInfo.fromJson(e as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  /// Enqueues a crawl of [url]. Returns the backend's job id.
  Future<String> triggerCrawl(
    String adminKey,
    String url,
    CrawlContentType contentType,
  ) async {
    final http.Response r = await _send(
      'POST',
      '/v1/crawl/trigger',
      adminKey,
      body: <String, dynamic>{'url': url, 'contentType': contentType.token},
    );
    if (r.statusCode != 202) {
      throw BackendException(r.statusCode, r.body);
    }
    final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
    return '${j['jobId']}';
  }
}
