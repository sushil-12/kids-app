import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's single seam to the network.
///
/// Phase 1 ships **fully offline**, so the only binding is [OfflineApiClient],
/// which refuses every call. When the backend + AI proxy land (see
/// `claude-ai.md` §4), a real client is injected via [apiClientProvider] and
/// nothing else in the app changes.
///
/// Hard rule from the plan: the app NEVER calls a model API directly. Every
/// request goes through the server proxy this interface fronts, where auth,
/// quota, moderation and caching live. Keys never ship in the binary.
abstract interface class ApiClient {
  /// Whether a backend is configured. `false` in Phase 1 (offline-only).
  bool get isAvailable;

  /// POSTs [body] as JSON to the proxy [path] and returns the decoded response.
  ///
  /// Throws [ApiUnavailableException] when [isAvailable] is `false`. Callers
  /// must always have a non-AI fallback (House Rule: offline never breaks).
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  );
}

/// Thrown when an [ApiClient] call is made while no backend is configured.
class ApiUnavailableException implements Exception {
  const ApiUnavailableException();

  @override
  String toString() =>
      'ApiUnavailableException: the app is offline-only in this build';
}

/// The Phase 1 binding: there is no backend, so every call fails fast and
/// loudly rather than pretending. Features detect this via [isAvailable] and
/// fall back to their on-device path.
class OfflineApiClient implements ApiClient {
  const OfflineApiClient();

  @override
  bool get isAvailable => false;

  @override
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async =>
      throw const ApiUnavailableException();
}

/// The injected network client. Defaults to [OfflineApiClient]; a real proxy
/// client is supplied by overriding this provider once the backend exists.
final apiClientProvider = Provider<ApiClient>(
  (Ref ref) => const OfflineApiClient(),
);
