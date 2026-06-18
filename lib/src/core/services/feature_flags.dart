import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Stable persistence keys for each toggle. Never rename — they are written to
/// Hive and (later) mirrored by Remote Config. Public so tests and the (future)
/// parent settings can flip a flag without stringly-typed guesswork.
abstract final class FeatureFlagKeys {
  /// On-device adaptive difficulty (Tier 2 — free, private). On by default.
  static const String adaptiveDifficulty = 'adaptiveDifficulty';

  /// ML Kit scribble recognition ("I see a cat!"). Off until built.
  static const String scribbleRecognition = 'scribbleRecognition';

  /// ML Kit photo→coloring. Off until built + consent-gated (§2C).
  static const String photoToColoring = 'photoToColoring';

  /// Tier-3 weekly parent report via the AI proxy. Off until the backend lands.
  static const String parentReports = 'parentReports';
}

/// Immutable snapshot of which AI/backend features are enabled.
///
/// Defaults reflect the plan's tiering (`claude-ai.md` §0): the on-device,
/// compliance-clear feature ships on; everything that needs a backend or the
/// §2C compliance review stays off until it exists. A [FeatureFlagStore] can
/// override any default per device/region/version with no app update.
@immutable
class FeatureFlags {
  const FeatureFlags({
    this.adaptiveDifficulty = true,
    this.scribbleRecognition = false,
    this.photoToColoring = false,
    this.parentReports = false,
  });

  final bool adaptiveDifficulty;
  final bool scribbleRecognition;
  final bool photoToColoring;
  final bool parentReports;
}

/// Persistence boundary for flag overrides. Behind an interface so the
/// view-model can be unit-tested with an in-memory store, with no Hive setup.
///
/// `null` from [overrideFor] means "no override — use the code default".
abstract interface class FeatureFlagStore {
  bool? overrideFor(String key);
  void setOverride(String key, {required bool value});
}

/// In-memory [FeatureFlagStore]. The default binding: flags must never block
/// the app (or a test) that hasn't wired Hive, and they have sensible code
/// defaults. `main()` swaps in the Hive-backed store for persistence.
class EphemeralFeatureFlagStore implements FeatureFlagStore {
  EphemeralFeatureFlagStore([Map<String, bool>? initial])
      : _values = <String, bool>{...?initial};

  final Map<String, bool> _values;

  @override
  bool? overrideFor(String key) => _values[key];

  @override
  void setOverride(String key, {required bool value}) =>
      _values[key] = value;
}

/// Hive-backed [FeatureFlagStore]. The box is opened once at app start
/// (see `main.dart`); only explicitly-set overrides are stored.
class HiveFeatureFlagStore implements FeatureFlagStore {
  HiveFeatureFlagStore(this._box);

  /// Name of the Hive box that holds flag overrides.
  static const String boxName = 'feature_flags';

  final Box<dynamic> _box;

  @override
  bool? overrideFor(String key) {
    final dynamic v = _box.get(key);
    return v is bool ? v : null;
  }

  @override
  void setOverride(String key, {required bool value}) =>
      _box.put(key, value);
}

/// Injected flag persistence. Defaults to an in-memory store (code defaults);
/// `main()` overrides it with the Hive-backed store.
final featureFlagStoreProvider = Provider<FeatureFlagStore>(
  (Ref ref) => EphemeralFeatureFlagStore(),
);

/// Resolves the current [FeatureFlags] from code defaults plus any stored
/// overrides. Read it via `ref.watch(featureFlagsProvider)` to react to a
/// toggle, or `ref.read` for a one-off check.
class FeatureFlagsViewModel extends Notifier<FeatureFlags> {
  FeatureFlagStore get _store => ref.read(featureFlagStoreProvider);

  @override
  FeatureFlags build() => FeatureFlags(
        adaptiveDifficulty:
            _store.overrideFor(FeatureFlagKeys.adaptiveDifficulty) ?? true,
        scribbleRecognition:
            _store.overrideFor(FeatureFlagKeys.scribbleRecognition) ?? false,
        photoToColoring:
            _store.overrideFor(FeatureFlagKeys.photoToColoring) ?? false,
        parentReports:
            _store.overrideFor(FeatureFlagKeys.parentReports) ?? false,
      );

  /// Sets [key] (a [FeatureFlagKeys] constant) and rebuilds the snapshot.
  void setFlag(String key, {required bool value}) {
    _store.setOverride(key, value: value);
    ref.invalidateSelf();
  }
}

final featureFlagsProvider =
    NotifierProvider<FeatureFlagsViewModel, FeatureFlags>(
  FeatureFlagsViewModel.new,
);
