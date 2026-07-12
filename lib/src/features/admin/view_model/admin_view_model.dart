import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/backend_service.dart' show BackendException;
import '../data/admin_key_store.dart';
import '../data/admin_models.dart';
import '../data/admin_service.dart';

/// Severity of an [AdminLogEntry], used by the view to colour the line.
enum AdminLogLevel { info, success, error }

/// One line in the admin panel's action log — the "status of actions performed"
/// the operator sees. Messages are technical (URLs, job ids, HTTP codes) and are
/// composed here rather than localized.
@immutable
class AdminLogEntry {
  const AdminLogEntry(this.time, this.message, this.level);

  final DateTime time;
  final String message;
  final AdminLogLevel level;
}

/// Immutable state of the admin panel.
@immutable
class AdminState {
  const AdminState({
    this.adminKey,
    this.stats = const AsyncValue<BackendStats>.loading(),
    this.sources = const <CrawlSourceInfo>[],
    this.sourcesLoading = false,
    this.busy = false,
    this.log = const <AdminLogEntry>[],
  });

  /// The stored admin key, or `null` if not set yet.
  final String? adminKey;
  final AsyncValue<BackendStats> stats;
  final List<CrawlSourceInfo> sources;
  final bool sourcesLoading;

  /// True while a write action (e.g. trigger crawl) is in flight.
  final bool busy;
  final List<AdminLogEntry> log;

  bool get hasKey => adminKey != null;

  AdminState copyWith({
    Object? adminKey = _sentinel,
    AsyncValue<BackendStats>? stats,
    List<CrawlSourceInfo>? sources,
    bool? sourcesLoading,
    bool? busy,
    List<AdminLogEntry>? log,
  }) =>
      AdminState(
        adminKey:
            adminKey == _sentinel ? this.adminKey : adminKey as String?,
        stats: stats ?? this.stats,
        sources: sources ?? this.sources,
        sourcesLoading: sourcesLoading ?? this.sourcesLoading,
        busy: busy ?? this.busy,
        log: log ?? this.log,
      );

  static const Object _sentinel = Object();
}

/// Drives the admin panel: holds the key, fetches stats/sources, triggers
/// crawls, and records every action in [AdminState.log].
class AdminController extends Notifier<AdminState> {
  AdminService get _service => ref.read(adminServiceProvider);
  AdminKeyStore get _store => ref.read(adminKeyStoreProvider);

  @override
  AdminState build() => AdminState(adminKey: _store.read());

  /// Saves [key], then loads stats + sources. Trims whitespace.
  Future<void> setKey(String key) async {
    final String trimmed = key.trim();
    if (trimmed.isEmpty) return;
    _store.save(trimmed);
    state = state.copyWith(adminKey: trimmed);
    _append('Admin key saved.', AdminLogLevel.success);
    await refreshAll();
  }

  void clearKey() {
    _store.clear();
    state = const AdminState(adminKey: null);
    _append('Admin key cleared.', AdminLogLevel.info);
  }

  Future<void> refreshAll() async {
    await Future.wait<void>(<Future<void>>[refreshStats(), refreshSources()]);
  }

  Future<void> refreshStats() async {
    final String? key = state.adminKey;
    if (key == null) return;
    state = state.copyWith(stats: const AsyncValue<BackendStats>.loading());
    try {
      final BackendStats s = await _service.fetchStats(key);
      state = state.copyWith(stats: AsyncValue<BackendStats>.data(s));
    } catch (e, st) {
      state = state.copyWith(stats: AsyncValue<BackendStats>.error(e, st));
      _append('Stats failed: ${_describe(e)}', AdminLogLevel.error);
    }
  }

  Future<void> refreshSources() async {
    final String? key = state.adminKey;
    if (key == null) return;
    state = state.copyWith(sourcesLoading: true);
    try {
      final List<CrawlSourceInfo> list = await _service.fetchCrawlSources(key);
      state = state.copyWith(sources: list, sourcesLoading: false);
    } catch (e) {
      state = state.copyWith(sourcesLoading: false);
      _append('Sources failed: ${_describe(e)}', AdminLogLevel.error);
    }
  }

  /// Triggers a crawl and refreshes the source list so its status appears.
  Future<void> triggerCrawl(String url, CrawlContentType type) async {
    final String? key = state.adminKey;
    if (key == null) return;
    final String trimmed = url.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(busy: true);
    _append('Crawl queued: ${type.token} · $trimmed', AdminLogLevel.info);
    try {
      final String jobId = await _service.triggerCrawl(key, trimmed, type);
      _append('Crawl accepted (job $jobId).', AdminLogLevel.success);
      await refreshSources();
    } catch (e) {
      _append('Crawl failed: ${_describe(e)}', AdminLogLevel.error);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  String _describe(Object e) {
    if (e is BackendException) {
      return e.statusCode == 401 ? 'unauthorized (check key)' : 'HTTP ${e.statusCode}';
    }
    return 'network error';
  }

  void _append(String message, AdminLogLevel level) {
    state = state.copyWith(
      log: <AdminLogEntry>[
        AdminLogEntry(DateTime.now(), message, level),
        ...state.log,
      ],
    );
  }
}

/// On-device admin-key persistence. Defaults to in-memory; `main()` overrides
/// it with the Hive-backed store.
final adminKeyStoreProvider = Provider<AdminKeyStore>(
  (Ref ref) => EphemeralAdminKeyStore(),
);

final adminServiceProvider = Provider<AdminService>(
  (Ref ref) => const AdminService(),
);

final adminControllerProvider =
    NotifierProvider<AdminController, AdminState>(AdminController.new);
