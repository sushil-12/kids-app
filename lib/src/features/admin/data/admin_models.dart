import 'package:flutter/foundation.dart';

/// Snapshot of the backend's content stats (`GET /v1/stats`).
@immutable
class BackendStats {
  const BackendStats({
    required this.stories,
    required this.poems,
    required this.abcLessons,
    required this.openAiCallsToday,
    required this.crawledThisWeek,
  });

  final int stories;
  final int poems;
  final int abcLessons;
  final int openAiCallsToday;
  final int crawledThisWeek;

  factory BackendStats.fromJson(Map<String, dynamic> j) => BackendStats(
        stories: (j['stories'] as num?)?.toInt() ?? 0,
        poems: (j['poems'] as num?)?.toInt() ?? 0,
        abcLessons: (j['abcLessons'] as num?)?.toInt() ?? 0,
        openAiCallsToday: (j['openAiCallsToday'] as num?)?.toInt() ?? 0,
        crawledThisWeek: (j['crawledThisWeek'] as num?)?.toInt() ?? 0,
      );
}

/// The content types the crawler/generator understand.
enum CrawlContentType {
  story('story'),
  poem('poem'),
  abc('abc');

  const CrawlContentType(this.token);

  /// Wire value sent to / received from the backend.
  final String token;

  static CrawlContentType fromToken(String token) =>
      CrawlContentType.values.firstWhere(
        (CrawlContentType t) => t.token == token,
        orElse: () => CrawlContentType.story,
      );
}

/// One row from `GET /v1/crawl/sources` — a crawl source and its latest status.
@immutable
class CrawlSourceInfo {
  const CrawlSourceInfo({
    required this.id,
    required this.url,
    required this.contentType,
    required this.status,
    required this.lastCrawled,
  });

  final String id;
  final String url;
  final CrawlContentType contentType;

  /// One of `pending`, `success`, `failed`.
  final String status;

  /// ISO-8601 timestamp of the last crawl, or `null` if never crawled.
  final String? lastCrawled;

  factory CrawlSourceInfo.fromJson(Map<String, dynamic> j) => CrawlSourceInfo(
        id: j['id'] as String? ?? '',
        url: j['url'] as String? ?? '',
        contentType:
            CrawlContentType.fromToken(j['contentType'] as String? ?? 'story'),
        status: j['status'] as String? ?? 'pending',
        lastCrawled: j['lastCrawled'] as String?,
      );
}
